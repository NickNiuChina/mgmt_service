package Mgmt::Service::DB;

sub getConn($self) {
    # my $self = shift;
    print ("####DBUtils#################\n");

    my $config = $self->config;
    # p ($config->{db});
    say ($config->{db}->{dbname}); 
    print ("######DBUtils################\n");
}
1;