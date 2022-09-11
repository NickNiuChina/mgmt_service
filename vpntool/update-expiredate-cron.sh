# openssl x509 -enddate -noout -in /opt/easyrsa-all/pki/issued/carel.boss2.crt

 for cert in /opt/easyrsa-all/pki/issued/*.crt
do
    echo -e "\nCertificate: ${cert}"
    openssl x509 -enddate -noout -subject -in ${cert}
done
