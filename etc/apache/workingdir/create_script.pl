#
#  Generate Apache conf for proxy to bosses in VPN domain
#

use Net::IP;
my $ip = new Net::IP ('192.168.80.1 - 192.168.83.254') || die;
# Loop
do {
    $ipa = $ip->ip();
    @list = split (/\./, $ipa);
    #print $list[3] . "\n";
    $c = '';
    for $p (@list) {
	$hex = sprintf("%x", $p);
	$c = length($hex) == 2 ? $c . $hex : $c . '0' . $hex;
    }

    open(FH, '>>', "boss.conf") or die $!;
    open my $info, "gold" or die "Could not open gold: $!";
    while( my $str = <$info>)  {
      $str =~ s/IIIPPP/$ipa/g;
      $str =~ s/HEX/$c/g;
       print FH $str;
     }
     close FH;
} while (++$ip);


__END__
