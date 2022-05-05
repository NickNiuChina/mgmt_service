$i = `bash /opt/mgmt_service/vpntool/generate-requests.sh`;

print $i . "\n";


if ($i =~ /FATAL/m) {
    print "Founddddddddddddddddddddddddddd\n";
}
