#!/bin/bash

processS3event() {
    export MIN_UPLOAD_SIZE=1157 # id: uuid-type1; pwd: at least 12 chars; certificate 2048 bits
    export MAX_UPLOAD_SIZE=8192 # large enough to accomodate 8192 bits RSA certificate (~6KB)

    EVENT=$1
    echo "Retrieving S3 Bucket Name"
    export S3BUCKET=$(echo $EVENT | jq -crM ".s3.bucket.name")
    echo "Retrieving S3 Object Size"
    export OBJSIZE=$(echo $EVENT | jq -crM ".s3.object.size")
    echo "Retrieving S3 Object Key"
    export OBJKEY=$(echo $EVENT | jq -crM ".s3.object.key")
    echo "Retrieving S3 Object Key Version"
    export OBJKEYVERSION=$(echo $EVENT | jq -crM ".s3.object.versionId")


    # now calculate relative paths pretending unix semantics
    OBJKEYPREFIX=$(dirname /$OBJKEY)
    export OBJKEYSUFFIX=$(basename /$OBJKEY)
    OBJKEYPARENTPREFIX=$(realpath -m $OBJKEYPREFIX/../) # calculate relative parent path
    export OBJKEYPREFIX=${OBJKEYPREFIX:1} # strip leading "/"
    export OBJKEYPARENTPREFIX=${OBJKEYPARENTPREFIX:1} # strip leading "/"


    echo "Checking S3 Key Size Constraints"
    if [[ "$OBJSIZE" -lt $MIN_UPLOAD_SIZE || "$OBJSIZE" -gt $MAX_UPLOAD_SIZE  ]]; then
        echo "WARNING: $OBJKEY size is outside permitted range - DISCARDING REQUEST"
        aws s3 mv --quiet --no-progress --only-show-errors s3://$S3BUCKET/$OBJKEY s3://$S3BUCKET/$OBJKEYPARENTPREFIX/N-01-Discarded-Requests/$OBJKEYSUFFIX@$OBJKEYVERSION@SIZE_THRESHOLD
        exit 0
    fi

    echo "Retrieving Request File from S3"
    TMPFILE=$(mktemp -p $HOME) # $HOME is /tmp in lambda env
    aws s3 cp --quiet --no-progress --only-show-errors s3://$S3BUCKET/$OBJKEY $TMPFILE

    echo "Checking Retrieved file size"
    TMPFILE_SIZE=$(find $TMPFILE -type f -printf "%s")
    if [[ $TMPFILE_SIZE -ne $OBJSIZE ]]; then
        echo "WARNING: RETRIEVED FILE SIZE MISMATCHES WITH S3 EVENT: $OBJSIZE vs $TMPFILE_SIZE - DISCARDING REQUEST"
        aws s3 mv --quiet --no-progress --only-show-errors s3://$S3BUCKET/$OBJKEY s3://$S3BUCKET/$OBJKEYPARENTPREFIX/N-01-Discarded-Requests/$OBJKEYSUFFIX@$OBJKEYVERSION@SIZE_MISMATCH
        exit 0
    fi

    echo "Parsing Request file"
    REQFILE=$(<$TMPFILE) && rm -f $TMPFILE
    REQFILE_LF=$(echo "$REQFILE" | wc -l)
    if [[ $REQFILE_LF -lt 15 ]]; then
        echo "WARNING: NOT ENOUGH LINE FEEDS - DISCARDING REQUEST"
        aws s3 mv --quiet --no-progress --only-show-errors s3://$S3BUCKET/$OBJKEY s3://$S3BUCKET/$OBJKEYPARENTPREFIX/N-01-Discarded-Requests/$OBJKEYSUFFIX@$OBJKEYVERSION@NOT_ENOUGH_LF
        exit 0
    fi


    DEVICE_UUID=$(echo "$REQFILE" | head -1 | tail -1)
    DEVICE_PASSWORD=$(echo "$REQFILE" | head -2 | tail -1)
    DEVICE_CERT=$(echo "$REQFILE" | tail -n +3)

    # Check for UUID Version 1 Syntax
    UUID_TYPE1_REGEX='^[0-9a-f]{8}-[0-9a-f]{4}-[1][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
    if ! [[ $DEVICE_UUID =~ $UUID_TYPE1_REGEX ]]; then
        echo "WARNING: DEVICE_UUID is malformed - DISCARDING REQUEST"
        aws s3 mv --quiet --no-progress --only-show-errors s3://$S3BUCKET/$OBJKEY s3://$S3BUCKET/$OBJKEYPARENTPREFIX/N-01-Discarded-Requests/$OBJKEYSUFFIX@$OBJKEYVERSION@DEVICEUUID__MALFORMED
        exit 0
    fi

    if [[ ${#DEVICE_PASSWORD} -lt 12 ]]; then
        echo "WARNING: DEVICE_PASSWORD length less than 12 - DISCARDING REQUEST"
        aws s3 mv --quiet --no-progress --only-show-errors s3://$S3BUCKET/$OBJKEY s3://$S3BUCKET/$OBJKEYPARENTPREFIX/N-01-Discarded-Requests/$OBJKEYSUFFIX@$OBJKEYVERSION@DEVICEPASSWORD__MALFORMED
        exit 0
    fi

    set +e
    echo "$DEVICE_CERT" | openssl x509 -noout > /dev/null 2>/dev/null
    DEVICE_CERT_VERIFY_RESULT=$?
    set -e
    if [[ $DEVICE_CERT_VERIFY_RESULT -ne 0 ]]; then
        echo "WARNING: DEVICE_CERT is malformed - DISCARDING REQUEST"
        aws s3 mv --quiet --no-progress --only-show-errors s3://$S3BUCKET/$OBJKEY s3://$S3BUCKET/$OBJKEYPARENTPREFIX/N-01-Discarded-Requests/$OBJKEYSUFFIX@$OBJKEYVERSION@DEVICECERT__MALFORMED
        exit 0
    fi


    echo "Request File passed all verifications - MOVING TO VALIDATED REQUESTS"
    aws s3 mv --quiet --no-progress --only-show-errors s3://$S3BUCKET/$OBJKEY s3://$S3BUCKET/$OBJKEYPARENTPREFIX/N-02-Validated-Requests/$DEVICE_UUID.req

}

handler() {
    set -e
    EVENT_DATA=$1
    echo "$EVENT_DATA"

    LANG=C LC_ALL=C

    echo 'Retrieving Lambda S3 Record Length...'
    EVENTLENGTH=$(echo $EVENT_DATA | jq -crM ".Records | length")
    echo $EVENTLENGTH
    echo 'Entering Events Loop Processing...'
    for (( i=0; i<$EVENTLENGTH; i++ ))
    do
        echo "Retrieving Event $i"
        EVENT=$(echo $EVENT_DATA | jq -crM ".Records[$i]")
        echo "Retrieving Event $i - Source"
        EVENT_SOURCE=$(echo $EVENT | jq -crM ".eventSource")
        echo "Retrieving Event $i - Name"
        EVENT_NAME=$(echo $EVENT | jq -crM ".eventName")
        echo "Filtering on Event $i Source/Name"
        if [[ "$EVENT_SOURCE" == "aws:s3" && "$EVENT_NAME" == "ObjectCreated:Put" ]]; then
            echo "Calling Process on Event $i"
            processS3event $EVENT
        else
            echo "FATAL ERROR: Event $i Source/Name do not match !!"
        fi
    done
}
