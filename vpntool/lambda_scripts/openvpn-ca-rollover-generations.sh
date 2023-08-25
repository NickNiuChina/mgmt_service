#!/bin/bash


# Example of Input expected:

# {
# "Environment": "test",
# "OpenVPN_S3BucketPrefix": "rmpro-shared-eu01-",
# "ActOn": "clients",
# "TENANT": "SHARED-EU01",
# "TENANT_EMAIL": "iot.remotepro@carel.com",
# "TENANT_ORG": "CAREL INDUSTRIES S.p.A.",
# "TENANT_LOCALITY": "Brugine",
# "TENANT_PROVINCE": "PD",
# "TENANT_COUNTRY": "IT",
# "EASYRSA_CA_EXPIRE": 8060,
# "EASYRSA_CA_RSAKEYSIZE": 4096,
# "EASYRSA_CA_HASHALGO": "sha512",
# "EASYRSA_CERT_EXPIRE": 3660,
# "EASYRSA_CERT_RSAKEYSIZE": 2048,
# "EASYRSA_CERT_HASHALGO": "sha256",
# "EASYRSA_CERT_RENEW": 180
# }


doRollover() {
    set -e
    EVENT_DATA=$1
    echo "$EVENT_DATA"

    LANG=C LC_ALL=C
    
    
    QUIET=--quiet
    NOPROGRESS=--no-progress
    ONLYSHOWERRORS=--only-show-errors

    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/openssl/lib:/opt/openvpn/lib
    export OPENSSL=/opt/openssl/openssl
    export EASYRSACMD=/opt/easyrsa/easyrsa
    export OPENVPN=/opt/openvpn/openvpn

    if ! [[ -r ${OPENSSL} ]]; then
        echo "FATAL ERROR: CHECK OPENSSL LAMBDA LAYER"
        exit 5
    fi
    if ! [[ -r ${EASYRSACMD} ]]; then
        echo "FATAL ERROR: CHECK EASYRSA LAMBDA LAYER"
        exit 5
    fi
    if ! [[ -r ${OPENVPN} ]]; then
        echo "FATAL ERROR: CHECK OPENVPN LAMBDA LAYER"
        exit 5
    fi


    in_Environment=$(echo $EVENT_DATA | jq -crM ".Environment")
    in_OpenVPN_S3BucketPrefix=$(echo $EVENT_DATA | jq -crM ".OpenVPN_S3BucketPrefix")
    in_ActOn=$(echo $EVENT_DATA | jq -crM ".ActOn")
    in_DoServers=$(echo $EVENT_DATA | jq -crM ".DoServers")
    in_TENANT=$(echo $EVENT_DATA | jq -crM ".TENANT")
    in_TENANT_EMAIL=$(echo $EVENT_DATA | jq -crM ".TENANT_EMAIL")
    in_TENANT_ORG=$(echo $EVENT_DATA | jq -crM ".TENANT_ORG")
    in_TENANT_LOCALITY=$(echo $EVENT_DATA | jq -crM ".TENANT_LOCALITY")
    in_TENANT_PROVINCE=$(echo $EVENT_DATA | jq -crM ".TENANT_PROVINCE")
    in_TENANT_COUNTRY=$(echo $EVENT_DATA | jq -crM ".TENANT_COUNTRY")
    in_EASYRSA_CA_EXPIRE=$(echo $EVENT_DATA | jq -crM ".EASYRSA_CA_EXPIRE")
    in_EASYRSA_CA_RSAKEYSIZE=$(echo $EVENT_DATA | jq -crM ".EASYRSA_CA_RSAKEYSIZE")
    in_EASYRSA_CA_HASHALGO=$(echo $EVENT_DATA | jq -crM ".EASYRSA_CA_HASHALGO")
    in_EASYRSA_CERT_EXPIRE=$(echo $EVENT_DATA | jq -crM ".EASYRSA_CERT_EXPIRE")
    in_EASYRSA_CERT_RSAKEYSIZE=$(echo $EVENT_DATA | jq -crM ".EASYRSA_CERT_RSAKEYSIZE")
    in_EASYRSA_CERT_HASHALGO=$(echo $EVENT_DATA | jq -crM ".EASYRSA_CERT_HASHALGO")
    in_EASYRSA_CERT_RENEW=$(echo $EVENT_DATA | jq -crM ".EASYRSA_CERT_RENEW")

    export Environment=${in_Environment:-test}
    export OpenVPN_S3BucketPrefix=${in_OpenVPN_S3BucketPrefix:-rmpro-tenant-name-}
    
    
    export DoClients=false
    export DoServers=false
    case "$in_ActOn" in
        clients) export DoClients=true ;;
        servers) export DoServers=true ;;
        *) exit ;;
    esac

    export TENANT=${in_TENANT:-TENANT-NAME}
    export TENANT_EMAIL=${in_TENANT_EMAIL:-iot.remotepro@carel.com}
    export TENANT_ORG=${in_TENANT_ORG:-CAREL INDUSTRIES S.p.A.}
    export TENANT_LOCALITY=${in_TENANT_LOCALITY:-Brugine}
    export TENANT_PROVINCE=${in_TENANT_PROVINCE:-PD}
    export TENANT_COUNTRY=${in_TENANT_COUNTRY:-IT}
    export EASYRSA_CA_EXPIRE=${in_EASYRSA_CA_EXPIRE:-8060}
    export EASYRSA_CA_RSAKEYSIZE=${in_EASYRSA_CA_RSAKEYSIZE:-4096}
    export EASYRSA_CA_HASHALGO=${in_EASYRSA_CA_HASHALGO:-sha512}
    export EASYRSA_CERT_EXPIRE=${in_EASYRSA_CERT_EXPIRE:-1100}
    export EASYRSA_CERT_RSAKEYSIZE=${in_EASYRSA_CERT_RSAKEYSIZE:-2048}
    export EASYRSA_CERT_HASHALGO=${in_EASYRSA_CERT_HASHALGO:-sha256}
    export EASYRSA_CERT_RENEW=${in_EASYRSA_CERT_RENEW:-180}

    export EASYRSA_BATCH='1'
    export EASYRSA_DN='org'

    

    export S3BUCKET=${OpenVPN_S3BucketPrefix}${Environment}
    DATE_OF_ARCHIVE=$(date +"Archived-%Y%m%d-%H%M%S")



    # Ensure the workdir is pristine between lambda hot-invocations
    export WORKDIR=$(mktemp -d -p $HOME)
    cd $WORKDIR

    
    echo "########################################################################################################"
    echo "##"
    echo "## OpenVPN tls key - Generate and store in S3 a TLS Key if it is not already there"
    echo "##"
    echo "########################################################################################################"

    echo "Downloading TLS Key from S3"
    set +e
    aws s3 cp $NOPROGRESS $ONLYSHOWERRORS s3://$S3BUCKET/OPENVPN/tls.key .
    set -e
    [[ -r tls.key ]] || {
        echo "TLS Auth Key not found on S3 - Generating new and storing into S3"
        ${OPENVPN} --genkey --secret tls.key
        aws s3 cp $NOPROGRESS $ONLYSHOWERRORS tls.key s3://$S3BUCKET/OPENVPN/
    }


    if [[ "$DoServers" == "true" ]]; then
        echo "########################################################################################################"
        echo "##"
        echo "## Generating EasyRSA SERVERS CA for Environment: $Environment"
        echo "##"
        echo "########################################################################################################"
    
        cd ${WORKDIR}
        mkdir servers
        cd servers

        EASYRSA_OPENSSL=${OPENSSL} bash ${EASYRSACMD} init-pki --keysize=${EASYRSA_CERT_RSAKEYSIZE} --digest=${EASYRSA_CERT_HASHALGO}
        ${OPENSSL} rand -writerand pki/.rnd
        [[ -r pki/index.txt.attr ]] || echo "unique_subject = no" > pki/index.txt.attr
        cp $(dirname ${EASYRSACMD})/vars.example pki/vars
        VARSFILE=--vars=pki/vars
        

        export EASYRSA_REQ_COUNTRY="$TENANT_COUNTRY"
        export EASYRSA_REQ_PROVINCE="$TENANT_PROVINCE"
        export EASYRSA_REQ_CITY="$TENANT_LOCALITY"
        export EASYRSA_REQ_ORG="$TENANT_ORG"
        export EASYRSA_REQ_EMAIL="$TENANT_EMAIL"
        export EASYRSA_REQ_OU="$Environment $TENANT"
        export EASYRSA_REQ_CN="$Environment RemotePRO OpenVPN Servers CA"
    
        
    
        sed -i -e "s/^#set_var EASYRSA_DN.*/set_var EASYRSA_DN \"$EASYRSA_DN\"/" pki/vars
        sed -i -e "s/^#set_var EASYRSA_REQ_COUNTRY.*/set_var EASYRSA_REQ_COUNTRY \"$EASYRSA_REQ_COUNTRY\"/" pki/vars
        sed -i -e "s/^#set_var EASYRSA_REQ_PROVINCE.*/set_var EASYRSA_REQ_PROVINCE \"$EASYRSA_REQ_PROVINCE\"/" pki/vars
        sed -i -e "s/^#set_var EASYRSA_REQ_CITY.*/set_var EASYRSA_REQ_CITY \"$EASYRSA_REQ_CITY\"/" pki/vars
        sed -i -e "s/^#set_var EASYRSA_REQ_ORG.*/set_var EASYRSA_REQ_ORG \"$EASYRSA_REQ_ORG\"/" pki/vars
        sed -i -e "s/^#set_var EASYRSA_REQ_EMAIL.*/set_var EASYRSA_REQ_EMAIL \"$EASYRSA_REQ_EMAIL\"/" pki/vars
        sed -i -e "s/^#set_var EASYRSA_REQ_OU.*/set_var EASYRSA_REQ_OU \"$EASYRSA_REQ_OU\"/" pki/vars
        sed -i -e "s/^#set_var EASYRSA_CERT_EXPIRE.*/set_var EASYRSA_CERT_EXPIRE \"$EASYRSA_CERT_EXPIRE\"/" pki/vars
        sed -i -e "s/^#set_var EASYRSA_CERT_RENEW.*/set_var EASYRSA_CERT_RENEW \"$EASYRSA_CERT_RENEW\"/" pki/vars
        
    
        EASYRSA_OPENSSL=${OPENSSL} \
        EASYRSA_DN=$EASYRSA_DN \
        EASYRSA_REQ_COUNTRY=$EASYRSA_REQ_COUNTRY \
        EASYRSA_REQ_PROVINCE=$EASYRSA_REQ_PROVINCE \
        EASYRSA_REQ_CITY=$EASYRSA_REQ_CITY \
        EASYRSA_REQ_ORG=$EASYRSA_REQ_ORG \
        EASYRSA_REQ_EMAIL=$EASYRSA_REQ_EMAIL \
        EASYRSA_REQ_OU=$EASYRSA_REQ_OU \
        EASYRSA_REQ_CN=$EASYRSA_REQ_CN \
    
        EASYRSA_CA_EXPIRE=$EASYRSA_CA_EXPIRE \
        EASYRSA_CERT_EXPIRE=$EASYRSA_CERT_EXPIRE \
        EASYRSA_CERT_RENEW=$EASYRSA_CERT_RENEW \
    
    
        bash ${EASYRSACMD} $VARSFILE --batch --keysize=${EASYRSA_CA_RSAKEYSIZE} --digest=${EASYRSA_CA_HASHALGO} build-ca nopass
    fi

    
    if [[ "$DoClients" == "true" ]]; then
        echo "########################################################################################################"
        echo "##"
        echo "## Generating EasyRSA CLIENTS CA for Environment: $Environment"
        echo "##"
        echo "########################################################################################################"
    
        cd ${WORKDIR}
        mkdir clients
        cd clients

        EASYRSA_OPENSSL=${OPENSSL} bash ${EASYRSACMD} init-pki --keysize=${EASYRSA_CERT_RSAKEYSIZE} --digest=${EASYRSA_CERT_HASHALGO}
        ${OPENSSL} rand -writerand pki/.rnd
        [[ -r pki/index.txt.attr ]] || echo "unique_subject = no" > pki/index.txt.attr
        cp $(dirname ${EASYRSACMD})/vars.example pki/vars
        VARSFILE=--vars=pki/vars
        

        export EASYRSA_REQ_COUNTRY="$TENANT_COUNTRY"
        export EASYRSA_REQ_PROVINCE="$TENANT_PROVINCE"
        export EASYRSA_REQ_CITY="$TENANT_LOCALITY"
        export EASYRSA_REQ_ORG="$TENANT_ORG"
        export EASYRSA_REQ_EMAIL="$TENANT_EMAIL"
        export EASYRSA_REQ_OU="$Environment $TENANT"
        export EASYRSA_REQ_CN="$Environment RemotePRO OpenVPN Clients CA"
    
        
    
        sed -i -e "s/^#set_var EASYRSA_DN.*/set_var EASYRSA_DN \"$EASYRSA_DN\"/" pki/vars
        sed -i -e "s/^#set_var EASYRSA_REQ_COUNTRY.*/set_var EASYRSA_REQ_COUNTRY \"$EASYRSA_REQ_COUNTRY\"/" pki/vars
        sed -i -e "s/^#set_var EASYRSA_REQ_PROVINCE.*/set_var EASYRSA_REQ_PROVINCE \"$EASYRSA_REQ_PROVINCE\"/" pki/vars
        sed -i -e "s/^#set_var EASYRSA_REQ_CITY.*/set_var EASYRSA_REQ_CITY \"$EASYRSA_REQ_CITY\"/" pki/vars
        sed -i -e "s/^#set_var EASYRSA_REQ_ORG.*/set_var EASYRSA_REQ_ORG \"$EASYRSA_REQ_ORG\"/" pki/vars
        sed -i -e "s/^#set_var EASYRSA_REQ_EMAIL.*/set_var EASYRSA_REQ_EMAIL \"$EASYRSA_REQ_EMAIL\"/" pki/vars
        sed -i -e "s/^#set_var EASYRSA_REQ_OU.*/set_var EASYRSA_REQ_OU \"$EASYRSA_REQ_OU\"/" pki/vars
        sed -i -e "s/^#set_var EASYRSA_CERT_EXPIRE.*/set_var EASYRSA_CERT_EXPIRE \"$EASYRSA_CERT_EXPIRE\"/" pki/vars
        sed -i -e "s/^#set_var EASYRSA_CERT_RENEW.*/set_var EASYRSA_CERT_RENEW \"$EASYRSA_CERT_RENEW\"/" pki/vars
        
    
        EASYRSA_OPENSSL=${OPENSSL} \
        EASYRSA_DN=$EASYRSA_DN \
        EASYRSA_REQ_COUNTRY=$EASYRSA_REQ_COUNTRY \
        EASYRSA_REQ_PROVINCE=$EASYRSA_REQ_PROVINCE \
        EASYRSA_REQ_CITY=$EASYRSA_REQ_CITY \
        EASYRSA_REQ_ORG=$EASYRSA_REQ_ORG \
        EASYRSA_REQ_EMAIL=$EASYRSA_REQ_EMAIL \
        EASYRSA_REQ_OU=$EASYRSA_REQ_OU \
        EASYRSA_REQ_CN=$EASYRSA_REQ_CN \
    
        EASYRSA_CA_EXPIRE=$EASYRSA_CA_EXPIRE \
        EASYRSA_CERT_EXPIRE=$EASYRSA_CERT_EXPIRE \
        EASYRSA_CERT_RENEW=$EASYRSA_CERT_RENEW \
    
    
        bash ${EASYRSACMD} $VARSFILE --batch --keysize=${EASYRSA_CA_RSAKEYSIZE} --digest=${EASYRSA_CA_HASHALGO} build-ca nopass
    fi



    if [[ "$DoServers" == "true" ]]; then
        echo "########################################################################################################"
        echo "##"
        echo "## Generating EasyRSA SERVERS CA Bundles"
        echo "##"
        echo "########################################################################################################"

        cd ${WORKDIR}

        
        echo "Downloading current Clients CA to be trusted by Servers"
        aws s3 cp --recursive $NOPROGRESS $ONLYSHOWERRORS s3://$S3BUCKET/OPENVPN/Servers/Generations/current/ servers/pki/ --exclude "*" --include "clients-cabundle.pem"
        if ! [[ -f servers/pki/clients-cabundle.pem ]]; then
            echo "clients-cabundle.pem not found on S3 current generation - setting to empty file"
            touch servers/pki/clients-cabundle.pem
        fi

        echo "Downloading previous Server CA to later update Clients S3"
        mkdir servers-previous
        aws s3 cp --recursive $NOPROGRESS $ONLYSHOWERRORS s3://$S3BUCKET/OPENVPN/Servers/Generations/previous/ servers-previous/ --exclude "*" --include "ca.crt"
        if ! [[ -f servers-previous/ca.crt ]]; then
            echo "previous server ca.crt not found, faking an empty one"
            touch servers-previous/ca.crt
        fi
        cat servers/pki/ca.crt servers-previous/ca.crt > servers-cabundle.pem

    fi



    if [[ "$DoClients" == "true" ]]; then
        echo "########################################################################################################"
        echo "##"
        echo "## Generating EasyRSA CLIENTS CA Bundles"
        echo "##"
        echo "########################################################################################################"
        
        cd ${WORKDIR}

        
        echo "Downloading current Servers CA to be trusted by Clients"
        aws s3 cp --recursive $NOPROGRESS $ONLYSHOWERRORS s3://$S3BUCKET/OPENVPN/Clients/Generations/current/ clients/pki/ --exclude "*" --include "servers-cabundle.pem"
        if ! [[ -f clients/pki/servers-cabundle.pem ]]; then
            echo "servers-cabundle.pem not found on S3 current generation - setting to empty file"
            touch clients/pki/servers-cabundle.pem
        fi

        echo "Downloading previous Clients CA to later update Servers S3"
        mkdir clients-previous
        aws s3 cp --recursive $NOPROGRESS $ONLYSHOWERRORS s3://$S3BUCKET/OPENVPN/Servers/Generations/previous/ clients-previous/ --exclude "*" --include "ca.crt"
        if ! [[ -f clients-previous/ca.crt ]]; then
            echo "previous clients ca.crt not found, faking an empty one"
            touch clients-previous/ca.crt
        fi
        cat clients/pki/ca.crt clients-previous/ca.crt > clients-cabundle.pem

    fi



    if [[ "$DoServers" == "true" ]]; then
        echo "########################################################################################################"
        echo "##"
        echo "## Versioning SERVERS Generations and upload"
        echo "##"
        echo "########################################################################################################"
        
        cd ${WORKDIR}

        echo "Storing empty directories structure for S3 archiving"
        pushd servers/pki >/dev/null
        find -type d -empty -print0 | tar cf - --null -T - > empty-dirs.tar        
        popd >/dev/null


        # Remove .rnd seed
        rm -f servers/pki/.rnd
    
        # Ensure we have enough Lambda time to complete S3 final parts ~10min
        now=$(date +%s%3N)
        lambda_remaining_ms=$(( AWS_LAMBDA_DEADLINE_MS - now ))
        echo "Remaining Lambda time ($lambda_remaining_ms ms left) is enough"
        if [[ $lambda_remaining_ms -lt 600000 ]]; then
            echo "FATAL ERROR: Not enough Lambda time to safely update S3 store - $lambda_remaining_ms ms left"
            cd && rm -rf $WORKDIR
            exit 5
        fi


        echo "Archiving PREVIOUS Servers generation to S3 Archive path"
        aws s3 mv --recursive $NOPROGRESS $ONLYSHOWERRORS s3://$S3BUCKET/OPENVPN/Servers/Generations/previous s3://$S3BUCKET/OPENVPN/Servers/Generations/archive/$DATE_OF_ARCHIVE
        
        echo "Switching CURRENT to PREVIOUS generation for Servers in S3"
        aws s3 mv --recursive $NOPROGRESS $ONLYSHOWERRORS s3://$S3BUCKET/OPENVPN/Servers/Generations/current s3://$S3BUCKET/OPENVPN/Servers/Generations/previous
        
        echo "Uploading new Servers Generation to CURRENT in S3"
        pushd servers >/dev/null
        aws s3 sync $NOPROGRESS $ONLYSHOWERRORS pki s3://$S3BUCKET/OPENVPN/Servers/Generations/current --delete
        popd >/dev/null
        
        echo "Updating Clients S3 store with new Server CA Bundle"
        aws s3 cp $NOPROGRESS $ONLYSHOWERRORS servers-cabundle.pem s3://$S3BUCKET/OPENVPN/Clients/Generations/current/
        
    fi



    
    
    if [[ "$DoClients" == "true" ]]; then
        echo "########################################################################################################"
        echo "##"
        echo "## Versioning CLIENTS Generations and upload"
        echo "##"
        echo "########################################################################################################"
        
        cd ${WORKDIR}


        echo "Storing empty directories structure for S3 archiving"
        pushd clients/pki >/dev/null
        find -type d -empty -print0 | tar cf - --null -T - > empty-dirs.tar        
        popd >/dev/null


        # Remove .rnd seed
        rm -f clients/pki/.rnd
    
        # Ensure we have enough Lambda time to complete S3 final parts ~10min
        now=$(date +%s%3N)
        lambda_remaining_ms=$(( AWS_LAMBDA_DEADLINE_MS - now ))
        echo "Remaining Lambda time ($lambda_remaining_ms ms left) is enough"
        if [[ $lambda_remaining_ms -lt 600000 ]]; then
            echo "FATAL ERROR: Not enough Lambda time to safely update S3 store - $lambda_remaining_ms ms left"
            cd && rm -rf $WORKDIR
            exit 5
        fi


        echo "Archiving PREVIOUS Clients generation to S3 Archive path"
        aws s3 mv --recursive $NOPROGRESS $ONLYSHOWERRORS s3://$S3BUCKET/OPENVPN/Clients/Generations/previous s3://$S3BUCKET/OPENVPN/Clients/Generations/archive/$DATE_OF_ARCHIVE
        
        echo "Switching CURRENT to PREVIOUS generation for Clients in S3"
        aws s3 mv --recursive $NOPROGRESS $ONLYSHOWERRORS s3://$S3BUCKET/OPENVPN/Clients/Generations/current s3://$S3BUCKET/OPENVPN/Clients/Generations/previous
        
        echo "Uploading new Clients Generation to CURRENT in S3"
        pushd clients >/dev/null
        aws s3 sync $NOPROGRESS $ONLYSHOWERRORS pki s3://$S3BUCKET/OPENVPN/Clients/Generations/current --delete
        popd >/dev/null
        
        echo "Updating Servers S3 store with new Clients CA Bundle"
        aws s3 cp $NOPROGRESS $ONLYSHOWERRORS clients-cabundle.pem s3://$S3BUCKET/OPENVPN/Servers/Generations/current/
        
    fi

}

handler() {
    correct_confirm_date=$(date +"%Y%m%d-%H")
    env_confirm_date=${confirm_date:-xxx}
    if [[ "$env_confirm_date" == "$correct_confirm_date" ]]; then
        doRollover "$1"
    else
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        echo "!!!"
        echo "!!! TO BE EXTRA SURE THAT YOU REALLY WANT TO RUN THIS PROCEDURE"
        echo "!!!   YOU MUST SET ENVIRONMENT VARIABLE 'confirm_date' TO CORRECT DATE AND UTC HOUR OF EXECUTION"
        echo "!!!"
        echo "!!!   FOR EXAMPLE, TO RUN NOW, YOU WOULD NEED: confirm_date=$correct_confirm_date"
        echo "!!!"
        echo "!!!   PLEASE DOUBLE CHECK THE ENVIRONMENT ON WHICH YOU WANT TO OPERATE"
        echo "!!!"
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        exit 1
    fi
}

# vim:set ts=2 sw=2 et: