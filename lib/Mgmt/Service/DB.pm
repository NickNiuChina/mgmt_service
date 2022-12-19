package Mgmt::Service::DB;
use strict;
use warnings;
use DBI;
use Data::Printer;
#
# DB interface
# 

our $dbh;

sub connect {   

    my $class = shift;
    # this is the mojolicious crontroller object, contains the db connection info
    my $c = shift;
    $c->log->info("Running to DB interface.");
    my $config = $c->config;
    # p ($config);
    my $driver   = $config->{db}->{driver};
    my $database = $config->{db}->{dbname};
    my $host = $config->{db}->{host};
    my $port = $config->{db}->{port};
    my $dsn = "DBI:$driver:dbname=$database;host=$host;port=$port";
    my $userid = $config->{db}->{uname};
    my $password = $config->{db}->{passwd};
    
    if ($dbh) {   
        $c->log->warn('Connect when already connected');  
        $c->log->info("Clean the old connection info.");   
        $dbh = undef;  
    } 

    my $tries = 0;
    do {
        eval {
            $dbh = DBI->connect($dsn, $userid, $password, { RaiseError => 1 }) or die $DBI::errstr;
        };
        if ((!$dbh) && (++$tries < 5)) {
            $c->log->fatal('connect failed: %s', $DBI::errstr ? $DBI::errstr : 'unknown');
            $c->log->info('will retry in 10');
            sleep 5;
        }
    } while (!$dbh && ($tries < 5));

    $c->log->info("Giving up on connect") if !$dbh;
    $c->log->info("DB interface done.");  
    return $dbh;   
}

sub disconnect {   
    my $class = shift;
    my $c = shift;

    if (!$dbh) {   
        return 0;   
    } 
    eval {   
        local $SIG{__DIE__} = sub { return (0); }; 
        local $SIG{__WARN__} = sub { return (0); }; 
        $dbh->disconnect(); 
    }; 
    $dbh = undef;   
    return 1;   
}  

1;