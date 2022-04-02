#!/usr/bin/env perl
use DBI;
use strict;
use warnings;
use File::Basename;
use POSIX qw(strftime);

my $prog = basename($0);
print "Prog name: $prog\n";
# like config
my $clientIssuedDir = '/opt/easyrsa-all/pki/issued';
my $driver   = "Pg"; 
my $database = "mgmtdb";
my $dsn = "DBI:$driver:dbname=$database;host=127.0.0.1;port=5432";
my $userid = "mgmt";
my $password = "rootroot";

my $dbh = DBI->connect($dsn, $userid, $password, 
	{
	RaiseError => 1,
	pg_server_prepare => 1,
       }
)  or die $DBI::errstr;

my $clientName;
my $stmt;
my $sth;
my $rv;
my $rows;

my @client_crt_files = glob "$clientIssuedDir/*.crt";
for my $file (@client_crt_files) {
    my $filename = basename($file);
    $filename =~ /^(.*)\.\w+$/;
    $clientName = $1;
    $stmt = q(SELECT cn,releasedate,expiredate from cnexpiredate where cn = ?;);
    $sth = $dbh->prepare($stmt);
    $rv = $sth->execute($clientName) or die $DBI::errstr;
    if($rv < 0){
      print $DBI::errstr;
    }
    $rows = $sth->rows;
    my $releaseDate = `openssl x509 -noout -text -in $file | grep -i "Not Before" | awk -F 'Not Before: ' {'print \$2'}`;
    my $expireDate = `openssl x509 -noout -text -in $file | grep -i "Not After" | awk -F 'Not After : ' {'print \$2'}`;
    chomp $releaseDate;
    chomp $expireDate;
    if (not $rows) {
	$stmt = q(INSERT INTO cnexpiredate (cn, releasedate, expiredate) values (?, ?, ?););
	$sth = $dbh->prepare($stmt);
	$rv = $sth->execute($clientName, $releaseDate, $expireDate) or die $DBI::errstr;
    }
    if ($rows) {
        my @row = $sth->fetchrow_array();
	if (not $row[2]){
	    my $cn = $row[0];
	    $stmt = q(UPDATE cnexpiredate set releasedate = ?, expiredate = ? where cn = ?;);
            $sth = $dbh->prepare($stmt);
            $rv = $sth->execute($releaseDate, $expireDate, $clientName) or die $DBI::errstr;
	    print "Update statement done for: $cn.\n";

	}
    } 
}

$sth->finish();
$dbh->disconnect();
1;
