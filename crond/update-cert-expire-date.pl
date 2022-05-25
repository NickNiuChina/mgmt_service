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
    $stmt = q(SELECT cn,releasedate,expiredate from ovpnclients where cn = ?;);
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
    print "$rows\n";
    print "$clientName: \n\t$releaseDate\n\t$expireDate\n";
    if (not $rows) {
<<<<<<< HEAD
	print "Not found, exec insert\n";
	$stmt = q(INSERT INTO ovpnclients (cn, releasedate, expiredate) values (?, ?, ?););
	$sth = $dbh->prepare($stmt);
	$rv = $sth->execute($clientName, $releaseDate, $expireDate) or die $DBI::errstr;
    }
    if ($rows) {
        my @row = $sth->fetchrow_array();
	print "Found: @row\n";
	my $cn = $row[0];
	$stmt = q(UPDATE ovpnclients set releasedate = ?, expiredate = ? where cn = ?;);
        $sth = $dbh->prepare($stmt);
        $rv = $sth->execute($releaseDate, $expireDate, $clientName) or die $DBI::errstr;
	print "Update statement done for: $cn.\n";

    } 
=======
        print "Not found, exec insert\n";
        $stmt = q(INSERT INTO ovpnclients (cn, releasedate, expiredate) values (?, ?, ?););
        $sth = $dbh->prepare($stmt);
        $rv = $sth->execute($clientName, $releaseDate, $expireDate) or die $DBI::errstr;
    }
    if ($rows) {
        my @row = $sth->fetchrow_array();
        print "Found: @row\n";
        my $cn = $row[0];
        $stmt = q(UPDATE ovpnclients set releasedate = ?, expiredate = ? where cn = ?;);
        $sth = $dbh->prepare($stmt);
        $rv = $sth->execute($releaseDate, $expireDate, $clientName) or die $DBI::errstr;
        print "Update statement done for: $cn.\n";

    }
>>>>>>> d92557fcde53d49876f79ead158738bdfc79a97e
}

$sth->finish();
$dbh->disconnect();
1;