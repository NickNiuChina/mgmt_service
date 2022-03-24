package Mgmt::Service;
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
  # $r->get('/upload_image')->to(controller => 'UploadImageController', action => 'index');

  $r->get('/')->to('Base#index');
  $r->get('/service')->to('Login#index');
  
  $r->get('/service/issue')->to('Views#issuecert');
  $r->post('/service/issue/upload')->to('Views#reqUpload');

  $r->get('/service/reqs')->to('Views#reqFilesList');
  $r->post('/service/reqs/list')->to('Views#reqsClientsListJson');
  
  $r->get('/service/certed')->to('Views#certedClientsList');
  $r->post('/service/certed/list')->to('Views#certedClientsListJson');
  
  
  ###### Other Urls ########
  # $r->get('/bar')->to('Foo#bar');
  $r->get('/bar')->to(controller => 'Foo', action => 'bar');

}

1;
