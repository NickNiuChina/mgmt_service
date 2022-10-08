package Mgmt::Service::DB::DBUtils;
use Mojo::Base -base, -signatures;

use Exporter qw(import);
our @EXPORT = qw(getConn);

sub getConn($self) {
    # my $self = shift;
    print ("####DBUtils#################\n");

    my $config = $self->config;
    # p ($config->{db});
    say ($config->{db}->{dbname}); 
    print ("######DBUtils################\n");
}
1;