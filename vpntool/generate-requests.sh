#!/bin/bash

# Generate openvpn client files for boss
# This was borrowed from Carel HQ
# This only works on Carel China Ali cloud ECS 'Openvpn server'.
# Released on Feb/28/2022 nick.niu@carel.com

# Tools and dirs
export OPENSSL=/usr/bin/openssl
export EASYRSACMD=/opt/easyrsa/easyrsa
# dir hold the req files to be dealt with
export REQDIR=/opt/reqs
# dir kept all the history client files
export BACKUPDIR=/opt/easyrsa-all
export TOOLDIR=/opt/easyrsa
export REQDIR=/opt/reqs
export REQDONEDIR=/opt/reqs-done

if ! [[ -r ${OPENSSL} ]]; then
    echo "FATAL ERROR: CHECK OPENSSL LAMBDA LAYER"
    exit 5
fi
if ! [[ -r ${EASYRSACMD} ]]; then
    echo "FATAL ERROR: CHECK EASYRSA LAMBDA LAYER"
    exit 5
fi

if [[ "`ls -al ${REQDIR}/ | grep req`" == "" ]]; then
    echo "FATAL ERROR: Did not see any NEW reqs files."
    exit 2
fi

# Ensure the workdir is a tmp dir in case any failure occurs 
export WORKDIR=$(mktemp -d -p /tmp)
cd $WORKDIR

# Downloading files needed
echo "Downloading files....:"
cp -r $TOOLDIR/* $WORKDIR
mkdir -p $WORKDIR/reqs
cp $REQDIR/* $WORKDIR/reqs

# ClientTemplates

echo "Free Space in Lambda Temp Dir:"
df -h $WORKDIR

echo "Checking CA Time Validity"
X_MARGIN_TIME_DAYS=${MARGIN_TIME_DAYS:-732} # defaults to >2 years
echo X_MARGIN_TIME_DAYS="$X_MARGIN_TIME_DAYS"
# this will match the commented version, too - inheriting easyrsa default if not specified in vars file
EASYRSA_CERT_RENEW=$(grep -P "set_var[[:space:]]*EASYRSA_CERT_EXPIRE\t*[0-9]*" $WORKDIR/vars | head -n1 | awk '{print $NF}' | sed -e 's/"//g' | sed -e 's/"//g')
echo EASYRSA_CERT_RENEW="$EASYRSA_CERT_RENEW"
#((CA_MIN_VALIDITY_SECONDS = (EASYRSA_CERT_RENEW + X_MARGIN_TIME_DAYS) * 86400))
# Currently we do not care when the CA will expire, this will be considered after 5 years at least.
((CA_MIN_VALIDITY_SECONDS = ( X_MARGIN_TIME_DAYS) * 86400))
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

# check Templates, later on this will be updated to seprated server and fetch from vpnserver.
echo "Checking OpenVPN Templates presence"
CABUNDLE=$WORKDIR/pki/ca.crt
TA=$WORKDIR/ta.key
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
for REQFILE in $WORKDIR/reqs/*.req; do
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
        echo "key-direction 1" >> $OVPN
        echo "<tls-auth>" >> $OVPN
        cat $TA >> $OVPN
        echo "</tls-auth>" >> $OVPN
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

PEPPER=`cat $WORKDIR/key`

    export PASSWORD=${PEPPER}${DEVICE_PASSWORD}${DEVICE_UUID}
    echo "###################################################################****************************************************"
    echo "\$PASSWORD:$PASSWORD"
    echo "\$PEPPER: $PEPPER"
    echo "\$DEVICE_PASSWORD: $DEVICE_PASSWORD"
    echo "\$DEVICE_UUID: ${DEVICE_UUID}"
    echo "###################################################################****************************************************"
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
# Move reqs file to /opt/reqs-done
#############################################################
mv -f $REQDIR/* $REQDONEDIR/


#############################################################
# OSS STORE UPDATE
#############################################################

cd $WORKDIR/pki

# Remove .rnd seed
rm -f .rnd

export OSSUTIL=/usr/local/bin/ossutil64
if ! [[ -r ${OSSUTIL} ]]; then
    echo "FATAL ERROR: CHECK OPENSSL LAMBDA LAYER"
    exit 5
fi

# Save the req cert key files for new clients
echo "Backup client req,key,crt files "
cp -fv $WORKDIR/pki/reqs/*.req $BACKUPDIR/pki/reqs/
cp -fv $WORKDIR/pki/private/*.key $BACKUPDIR/pki/private/
cp -fv $WORKDIR/pki/issued/*.crt $BACKUPDIR/pki/issued/
cp -fv $WORKDIR/pki/certs_by_serial/*.pem $BACKUPDIR/pki/certs_by_serial/

for FILE in $WORKDIR/pki/reqs/*.req; do
    ossutil64 cp $FILE oss://carelvpn/easyrsa/pki/reqs/ -f
done

for FILE in $WORKDIR/pki/private/*.key; do
    ossutil64 cp -f $FILE oss://carelvpn/easyrsa/pki/private/ -f
done

for FILE in $WORKDIR/pki/issued/*.crt; do
    ossutil64 cp -f $FILE oss://carelvpn/easyrsa/pki/issued/ -f
done

for FILE in $WORKDIR/pki/certs_by_serial/*.pem; do
    ossutil64 cp -f $FILE oss://carelvpn/easyrsa/pki/certs_by_serial/ -f
done

# Update OSS store
echo "Updating OSS store"
cd $WORKDIR
for REQFILE in $WORKDIR/reqs/*.req; do
    ossutil64 cp $REQFILE oss://carelvpn/reqs/ -f
done

for CERTFILE in $WORKDIR/*.p7mb64; do
    ossutil64 cp $CERTFILE oss://carelvpn/validated/ -f
    cp -fv $CERTFILE /opt/validated/
done

cd && rm -rf $WORKDIR

echo "SELFDEFINEDSUCCESS"; # This will tell the upload process is tatolly successlly
