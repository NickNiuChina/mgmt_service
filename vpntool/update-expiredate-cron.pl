#!/usr/bin/perl -w
use strict;
use DBI;
use Time::Piece;
use Data::Printer;

# openssl cmd to fetch expire date
# openssl x509 -enddate -noout -in /opt/easyrsa-all/pki/issued/carel.boss2.crt

my $driver   = "Pg";
my $database = "mgmtdb";
my $dsn = "DBI:$driver:dbname=$database;host=127.0.0.1;port=5432";
my $userid = "mgmt";
my $password = "rootroot";
my $dbh = DBI->connect($dsn, $userid, $password, { RaiseError => 1 }) or die $DBI::errstr;

my $sql = 'select cn, expiredate from ovpnclients';
my $sth = $dbh->prepare($sql);
$sth->execute();

my $cn;
my $expiredate;
my $cert_file;
my $cert_dir = '/opt/easyrsa-all';

my %updatelist;

while(my @aRow = $sth->fetchrow_array) {
    next unless $aRow[0] && $aRow[1]; # null?
    ($cn, $expiredate) = @aRow;
    $cert_file = $cert_dir . "/pki/issued/$cn.crt";
    next unless -e $cert_file; # skip if file not exist
    my $rc = `openssl x509 -enddate -noout -subject -in ${cert_file} 2>&1 `;
    print "\$rc: $rc\n";
    $expiredate = (split /=/, (split /\n/, $rc)[0])[1];
    chomp $expiredate;
    # print "##$expiredate##\n";
    ##Jul 24 01:36:15 2032 GMT##
    $expiredate =~ s/ GMT//;
    my $t = Time::Piece->strptime($expiredate,"%b  %d %H:%M:%S %Y");
    $t = $t->strftime("%Y-%m-%d %H:%M:%S");
    $updatelist{$cn} = $t ;
}

$sth->finish();
# p %updatelist;

$sql = 'update ovpnclients set expiredate= ? where cn= ?';
$sth = $dbh->prepare($sql);
foreach my $cn (keys %updatelist)
{
  # do whatever you want with $key and $value here ...
  $expiredate = $updatelist{$cn};
  printf "Updating client:  %-42s  %s\n", $cn . ',', $expiredate;
  $sth->execute($expiredate, $cn);
}

$sth->finish();
$dbh->disconnect();

__END__
# for cert in /opt/easyrsa-all/pki/issued/*.crt
# do
#     echo -e "\nCertificate: ${cert}"
#     openssl x509 -enddate -noout -subject -in ${cert}
# done

my $t = Time::Piece->strptime("20190626-102908.616319","%Y%m%d-%H%M%S");
say $t->strftime("%Y-%m-%d %H:%M:%S");
