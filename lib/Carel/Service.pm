package Carel::Service;
use Mojo::Base 'Mojolicious', -signatures;

# This method will run once at server start
sub startup ($self) {

  # Load configuration from config file
  my $config = $self->plugin('NotYAMLConfig');

  # Configure the application
  $self->secrets($config->{secrets});

  # Router
  my $r = $self->routes;

  # Normal route to controller
  # $r->get('/')->to('Example#welcome');
  $r->get('/')->to('Base#index');
  $r->get('/service')->to('Login#index');
  $r->get('/service/reqs')->to('Dashboard#reqFilesList');
  $r->get('/service/certed')->to('Dashboard#certedClientsList');
  $r->post('/service/certed/list')->to('Dashboard#certedClientsListJson');

  ###### Other ########
  $r->get('/bar')->to('Foo#bar');


}

1;
