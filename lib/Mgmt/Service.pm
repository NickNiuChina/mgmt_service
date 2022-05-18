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
  
  $r->get('/service/clientstatus')->to('Views#clientsStatus');
  $r->post('/service/clientstatus/list')->to('Views#clientsStatuslist');

  $r->get('/service/issue')->to('Views#issuecert');
  $r->post('/service/issue/upload')->to('Views#reqUpload');

  $r->get('/service/reqs')->to('Views#reqFilesList');
  $r->post('/service/reqs/list')->to('Views#reqsClientsListJson');
  $r->post('/service/reqs/delete')->to('Views#reqClientsDelete');
  # They can be especially useful for manually matching file names with extensions, rather than using format detection.
  # /music/song.mp3 -> /music/#filename -> {filename => 'song.mp3'}
  $r->get('/service/reqs/dl/#filename')->to('Views#reqClientsDownload');
  
  $r->get('/service/certed')->to('Views#certedClientsList');
  $r->post('/service/certed/list')->to('Views#certedClientsListJson');
  $r->post('/service/certed/delete')->to('Views#certedClientsDelete');
  $r->post('/service/certed/download')->to('Views#certedClientsDownload');
  $r->get('/service/certed/dl/#filename')->to('Views#certedClientsDownload');
  
  
  ###### Other Urls ########
  # $r->get('/bar')->to('Foo#bar');
  $r->get('/bar')->to(controller => 'Foo', action => 'bar');

}

1;
