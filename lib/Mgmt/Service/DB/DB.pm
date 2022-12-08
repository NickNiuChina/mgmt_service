package Mgmt::Service::DB;
use strict;
use warnings;
#
# DB interface
# 

our qw( @connect_args $dbh );

sub connect {   
    if ($dbh) {   
        trace('Connect when already connected');  
        #depth(10);   
        return $dbh;  
    } 

    my $tries = 0;
    do {
        eval {
            # Errors will die here rather than return false. Due to RaiseError above.
            $dbh = DBI->connect(@connect_args);
        };
        if (!$dbh && (++$tries < 20)) {
            trace('connect failed: %s', $DBI::errstr ? $DBI::errstr : 'unknown');
            trace('will retry in 10');
            sleep 10;
        }
    } while (!$dbh && ($tries < 20));

    trap("Giving up on connect") if !$dbh;

    # A trace in normal operation will hang the /var/service daemons.
    # A trace when the DB is down as above will also hang the daemon but
    # that will be worked arround by the daemons alarm().
    # The hang is because in the startup stage the trace goes to STDOUT.
    #trace('connected');

    return $dbh;   
}

1;