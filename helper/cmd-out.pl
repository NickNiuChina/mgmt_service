open(my $fh, "-|", "/bin/bash /opt/vpnTool/generate-requests.sh");
# print $fh; # GLOB
while ( my $line = <$fh> ) {
    print $line if $line =~ /NEW iiii/; 
}

#print $fh if $fh =~ /HHHHHHHHHHHHHHHHHHHHH/;
