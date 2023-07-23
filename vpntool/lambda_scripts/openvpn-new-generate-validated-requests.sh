#!/bin/bash

processS3event() {

    QUIET=--quiet
    NOPROGRESS=--no-progress
    ONLYSHOWERRORS=--only-show-errors

    export IN_PROGRESS_MARK='check_lambda_logs_and_then_delete_path_to_reset'
    export IN_PROGRESS_WARNING='ERROR__N-02-Validated-Requests@IN_PROGRESS__MUST_NOT_EXIST'


    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/openssl/lib
    export OPENSSL=/opt/openssl/openssl
    export EASYRSACMD=/opt/easyrsa/easyrsa

    if ! [[ -r ${OPENSSL} ]]; then
        echo "FATAL ERROR: CHECK OPENSSL LAMBDA LAYER"
        exit 5
    fi
    if ! [[ -r ${EASYRSACMD} ]]; then
        echo "FATAL ERROR: CHECK EASYRSA LAMBDA LAYER"
        exit 5
    fi


    # Ensure the workdir is pristine between lambda hot-invocations
    export WORKDIR=$(mktemp -d -p $HOME)
    cd $WORKDIR



    EVENT=$1
    echo "Retrieving S3 Bucket Name"
    export S3BUCKET=$(echo $EVENT | jq -crM ".s3.bucket.name")

    echo "Retrieving S3 Command File Name"
    export OBJKEY=$(echo $EVENT | jq -crM ".s3.object.key")

    # now calculate relative paths pretending unix path semantics
    OBJKEYPREFIX=$(dirname /$OBJKEY)
    S3COMMANDSPREFIX=$(realpath -m $OBJKEYPREFIX/../) # calculate Commands path prefix
    S3ROOTPREFIX=$(realpath -m $OBJKEYPREFIX/../../) # calculate root path prefix
    S3BASEROOTPREFIX=$(realpath -m $OBJKEYPREFIX/../../../) # calculate root path prefix
    export OBJKEYPREFIX=${OBJKEYPREFIX:1} # strip leading "/"
    export S3COMMANDSPREFIX=${S3COMMANDSPREFIX:1} # strip leading "/"
    export S3ROOTPREFIX=${S3ROOTPREFIX:1} # strip leading "/"
    export S3BASEROOTPREFIX=${S3BASEROOTPREFIX:1} # strip leading "/"
    echo "OBJKEYPREFIX=$OBJKEYPREFIX"
    echo "S3COMMANDSPREFIX=$S3COMMANDSPREFIX"
    echo "S3ROOTPREFIX=$S3ROOTPREFIX"
    echo "S3BASEROOTPREFIX=$S3BASEROOTPREFIX"


    echo "Checking if operation is already in progress"
    set +e
    already_in_progress=$(aws s3 ls s3://$S3BUCKET/$S3COMMANDSPREFIX/N-02-Validated-Requests@IN_PROGRESS)
    set -e

    if [[ "${already_in_progress}" != "" ]]; then
        echo "FATAL ERROR: Another operation might be already running - check Cloudwatch Lambda Logs - delete N-02-Validated-Requests@IN_PROGRESS to reset"
        echo "" | aws s3 cp $QUIET $NOPROGRESS $ONLYSHOWERRORS - s3://$S3BUCKET/$OBJKEYPREFIX/$IN_PROGRESS_WARNING
        aws s3 rm $QUIET $ONLYSHOWERRORS s3://$S3BUCKET/$OBJKEY
        exit
    fi


    echo "Setting IN_PROGRESS mark"
    echo "" | aws s3 cp $QUIET $NOPROGRESS $ONLYSHOWERRORS - s3://$S3BUCKET/$S3COMMANDSPREFIX/N-02-Validated-Requests@IN_PROGRESS/$IN_PROGRESS_MARK
    echo "Deleting Command File and error files"
    aws s3 rm --recursive $QUIET $ONLYSHOWERRORS s3://$S3BUCKET/$OBJKEYPREFIX/ --exclude "*" --include "$(basename /$OBJKEY)" --include "$IN_PROGRESS_WARNING"

    echo "Free Space in Lambda Temp Dir:"
    df -h $WORKDIR

    echo "Moving Validated Requests to Local"
    aws s3 mv --recursive $QUIET $NOPROGRESS $ONLYSHOWERRORS s3://$S3BUCKET/$S3COMMANDSPREFIX/N-02-Validated-Requests $WORKDIR/validated

    echo "Downloading OpenVPN Client Templates from s3://$S3BUCKET/$S3BASEROOTPREFIX/ClientTemplates/"
    aws s3 cp --recursive $QUIET $NOPROGRESS $ONLYSHOWERRORS s3://$S3BUCKET/$S3BASEROOTPREFIX/ClientTemplates/ $WORKDIR/clienttemplates

    echo "Downloading OpenVPN TLS Key from s3://$S3BUCKET/$S3BASEROOTPREFIX/tls.key"
    aws s3 cp $QUIET $NOPROGRESS $ONLYSHOWERRORS s3://$S3BUCKET/$S3BASEROOTPREFIX/tls.key $WORKDIR/

    echo "Downloading PKI Current Generation"
    aws s3 cp --recursive $QUIET $NOPROGRESS $ONLYSHOWERRORS s3://$S3BUCKET/$S3ROOTPREFIX/Generations/current/ $WORKDIR/pki
    echo "Fixing up S3 empty-dir limitations"
    tar xf $WORKDIR/pki/empty-dirs.tar -C $WORKDIR/pki/ >/dev/null 2>/dev/null

    echo "Free Space in Lambda Temp Dir:"
    df -h $WORKDIR

    echo "Checking CA Time Validity"
    X_MARGIN_TIME_DAYS=${MARGIN_TIME_DAYS:-732} # defaults to >2 years
    echo X_MARGIN_TIME_DAYS="$X_MARGIN_TIME_DAYS"
    # this will match the commented version, too - inheriting easyrsa default if not specified in vars file
    EASYRSA_CERT_RENEW=$(grep -P "set_var[[:space:]]*EASYRSA_CERT_EXPIRE\t*[0-9]*" $WORKDIR/pki/vars | head -n1 | awk '{print $NF}' | sed -e 's/"//g' | sed -e 's/"//g')
    echo EASYRSA_CERT_RENEW="$EASYRSA_CERT_RENEW"
    ((CA_MIN_VALIDITY_SECONDS = (EASYRSA_CERT_RENEW + X_MARGIN_TIME_DAYS) * 86400))
    echo CA_MIN_VALIDITY_SECONDS="$CA_MIN_VALIDITY_SECONDS"
    set +e
    ${OPENSSL} x509 -checkend $CA_MIN_VALIDITY_SECONDS  -noout -in $WORKDIR/pki/ca.crt
    CA_VALIDTIME=$?
    set -e
    if [[ $CA_VALIDTIME -ne 0 ]]; then
        echo "FATAL ERROR: Client CA will expire too soon"
        cd && rm -rf $WORKDIR
        exit
    fi


    echo "Checking OpenVPN Templates presence"
    CABUNDLE=$WORKDIR/pki/servers-cabundle.pem
    TA=$WORKDIR/tls.key
    for f in $CABUNDLE $TA; do
        if ! [[ -r $f ]]; then
            echo "FATAL ERROR: $f not readable"
            cd && rm -rf $WORKDIR
            exit
        fi
    done
    for p in udp tcp; do
        OVPN_T_header=$WORKDIR/clienttemplates/template-$p.header
        OVPN_T_footer=$WORKDIR/clienttemplates/template-$p.footer
        for f in $OVPN_T_header $OVPN_T_footer; do
            if ! [[ -r $f ]]; then
                echo "FATAL ERROR: $f not readable"
                cd && rm -rf $WORKDIR
                exit
            fi
        done
    done


    mkdir -p $WORKDIR/ovpn-profiles

    echo "Looping through all REQ files..."
    shopt -s nullglob
    for REQFILE in $WORKDIR/validated/*.req; do
        REQFILEBASE=$(basename $REQFILE)

        #############################################################
        # REQ File Integrity Checks
        #############################################################

        echo "Checking Integrity of request file $REQFILEBASE"
        REQ=$(<$REQFILE)

        REQ_LF=$(echo "$REQ" | wc -l)
        if [[ $REQ_LF -lt 15 ]]; then
            echo "FATAL ERROR: $REQFILEBASE - NOT ENOUGH LINE FEEDS"
            cd && rm -rf $WORKDIR
            exit
        fi

        DEVICE_UUID=$(echo "$REQ" | head -1 | tail -1)
        DEVICE_PASSWORD=$(echo "$REQ" | head -2 | tail -1)
        DEVICE_CERT=$(echo "$REQ" | tail -n +3)

        # Check for UUID Version 1 Syntax
        UUID_TYPE1_REGEX='^[0-9a-f]{8}-[0-9a-f]{4}-[1][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
        if ! [[ $DEVICE_UUID =~ $UUID_TYPE1_REGEX ]]; then
            echo "FATAL ERROR: $REQFILEBASE - DEVICE_UUID is malformed"
            cd && rm -rf $WORKDIR
            exit
        fi

        if [[ ${#DEVICE_PASSWORD} -lt 12 ]]; then
            echo "FATAL ERROR: $REQFILEBASE - DEVICE_PASSWORD length less than 12 chars"
            cd && rm -rf $WORKDIR
            exit
        fi

        set +e
        echo "$DEVICE_CERT" | ${OPENSSL} x509 -noout > /dev/null 2>/dev/null
        DEVICE_CERT_VERIFY_RESULT=$?
        set -e
        if [[ $DEVICE_CERT_VERIFY_RESULT -ne 0 ]]; then
            echo "FATAL ERROR: $REQFILEBASE - DEVICE_CERT is malformed"
            cd && rm -rf $WORKDIR
            exit
        fi

        #############################################################
        # CERTIFICATE GENERATION
        #############################################################

        CN=boss-$DEVICE_UUID
        client_crt=$WORKDIR/pki/issued/$CN.crt
        client_key=$WORKDIR/pki/private/$CN.key

        if [[ -r $client_key ]] && [[ -r $client_crt ]]; then
            echo "Certificate for $CN already exists, assuming this is a request to regenerate profiles and trying to reuse existing certificate"
            set +e
            pubout_pkey=$(${OPENSSL} pkey -in $client_key -pubout)
            pubout_cert=$(${OPENSSL} x509 -in $client_crt -pubkey -noout)
            if [[ "$pubout_pkey" != "$pubout_pkey" ]]; then
                echo "FATAL ERROR: Existing certificate/private key for $CN cannot be validated (CORRUPTED S3 STORE ?!)"
                cd && rm -rf $WORKDIR
                exit
            fi
            set -e
        else
            echo "Generating new certificate for $DEVICE_UUID with CN=$CN"
            ${OPENSSL} rand -writerand $WORKDIR/pki/.rnd
            set +e
            output=$(EASYRSA_OPENSSL=${OPENSSL} bash ${EASYRSACMD} --vars=pki/vars build-client-full $CN nopass)
            result=$?
            set -e
            if [[ $result -ne 0 ]]; then
                echo "FATAL ERROR: EasyRSA build-client-full failed for $CN:"
                echo "$output"
                cd && rm -rf $WORKDIR
                exit
            fi
        fi


        #############################################################
        # OPENVPN PROFILES GENERATION
        #############################################################

        echo "Generating OpenVPN Profiles for $CN"

        for p in udp tcp; do
            OVPN_T_header=$WORKDIR/clienttemplates/template-$p.header
            OVPN_T_footer=$WORKDIR/clienttemplates/template-$p.footer
            OVPN=$WORKDIR/ovpn-profiles/remotepro-$p.conf
            cat $OVPN_T_header > $OVPN
            echo >> $OVPN
            echo "<ca>" >> $OVPN
            cat $CABUNDLE >> $OVPN
            echo "</ca>" >> $OVPN
            echo "<cert>" >> $OVPN
            ${OPENSSL} x509 -in $client_crt >>$OVPN
            echo "</cert>" >> $OVPN
            echo "<key>" >> $OVPN
            cat $client_key >> $OVPN
            echo "</key>" >> $OVPN
            echo "<tls-crypt>" >> $OVPN
            cat $TA >> $OVPN
            echo "</tls-crypt>" >> $OVPN
            echo >> $OVPN
            cat $OVPN_T_footer >> $OVPN
        done


        #############################################################
        # OPENVPN PROFILES ARCHIVE BUNDLE
        #############################################################

        echo "Generating OpenVPN Profiles Archive Bundle for $CN"
        tar czf $WORKDIR/ovpn-profiles.tar.gz ovpn-profiles

        #############################################################
        # OPENVPN PROFILES ENCRYPTION
        #############################################################

        echo "Encrypting OpenVPN Profiles Archive Bundle for $CN"

        # This *must* be identical across every tenant/env and cannot be changed because it is hard-coded in every boss firmware
        export PEPPER=$(cat <<'EOF'
****secret salt***
EOF
)

        export PASSWORD=${PEPPER}${DEVICE_PASSWORD}${DEVICE_UUID}
        # 1-st level encryption - used to protect the openvpn profile itself in-transit
        ${OPENSSL} enc -aes-256-cbc -md sha512 -pbkdf2 -a -salt -in $WORKDIR/ovpn-profiles.tar.gz -out $WORKDIR/ovpn-profiles.enc -k "$PASSWORD"

        # 2-nd level encryption - used to protect boss from tampered .enc files
        echo "$DEVICE_CERT" > $WORKDIR/device_cert.pem
        ${OPENSSL} smime -encrypt -binary -aes-256-cbc -in $WORKDIR/ovpn-profiles.enc -out $WORKDIR/ovpn-profiles.p7m $WORKDIR/device_cert.pem
        
        # Base64 encoding - used to reduce risk of antimalware filtering false positives
        base64 $WORKDIR/ovpn-profiles.p7m > $WORKDIR/${DEVICE_UUID}.p7mb64

    done

    echo "Free Space in Lambda Temp Dir:"
    df -h $WORKDIR


    #############################################################
    # S3 STORE UPDATE
    #############################################################

    cd $WORKDIR/pki

    # Store updated empty directories structure for S3 archive
    find -type d -empty -print0 | tar cf - --null -T - > empty-dirs-new.tar
    set +e
    diff <(tar -tf empty-dirs.tar) <(tar -tf empty-dirs-new.tar) > /dev/null 2>/dev/null
    if [[ $? -eq 0 ]]; then
        rm -f empty-dirs-new.tar
    else
        mv -f empty-dirs-new.tar empty-dirs.tar
    fi
    set -e

    # Remove .rnd seed
    rm -f .rnd

    # Ensure we have enough Lambda time to complete S3 final uploads ~2min
    now=$(date +%s%3N)
    lambda_remaining_ms=$(( AWS_LAMBDA_DEADLINE_MS - now ))
    echo "Remaining Lambda time ($lambda_remaining_ms ms left) is enough"
    if [[ $lambda_remaining_ms -lt 120000 ]]; then
        echo "FATAL ERROR: Not enough Lambda time to safely udate S3 store - $lambda_remaining_ms ms left - please try with smaller batch size"
        cd && rm -rf $WORKDIR
        exit
    fi

    # Update S3 store
    echo "Updating S3 store"
    cd $WORKDIR
    aws s3 sync $NOPROGRESS $ONLYSHOWERRORS pki s3://$S3BUCKET/$S3ROOTPREFIX/Generations/current --delete

    # Uploading new P7MB64 Profiles
    echo "Uploading Generated Encrypted profiles"
    aws s3 cp --recursive $NOPROGRESS $ONLYSHOWERRORS ./ s3://$S3BUCKET/$S3COMMANDSPREFIX/N-ZZ-Generated-Profiles/ --exclude "*" --include "*.p7mb64"

    # Cleaning IN_PROGRESS
    echo "Cleaning IN_PROGRESS"
    aws s3 rm $ONLYSHOWERRORS --recursive s3://$S3BUCKET/$S3COMMANDSPREFIX/N-02-Validated-Requests@IN_PROGRESS

    # Cleanup workdir to free up space for next lambda hot-invocation
    cd && rm -rf $WORKDIR
}

handler() {
    set -e
    EVENT_DATA=$1
    echo "$EVENT_DATA"

    LANG=C LC_ALL=C

    echo 'Retrieving Lambda S3 Record Length...'
    EVENTLENGTH=$(echo $EVENT_DATA | jq -crM ".Records | length")
    if [[ $EVENTLENGTH -ne 1 ]]; then
        echo "FATAL ERROR: More than 1 Event is not supported!!"
        exit
    fi
    echo "Retrieving Event"
    EVENT=$(echo $EVENT_DATA | jq -crM ".Records[0]")
    echo "Retrieving Event Source"
    EVENT_SOURCE=$(echo $EVENT | jq -crM ".eventSource")
    echo "Retrieving Event Name"
    EVENT_NAME=$(echo $EVENT | jq -crM ".eventName")
    echo "Filtering on Event Source/Name"
    if [[ "$EVENT_SOURCE" == "aws:s3" && "$EVENT_NAME" = "ObjectCreated:Put" ]]; then
        echo "Calling Process on Event"
        processS3event $EVENT
    else
        echo "FATAL ERROR: Event Source/Name do not match !!"

    fi

}

#handler $1

# vim:set ts=2 sw=2 et: