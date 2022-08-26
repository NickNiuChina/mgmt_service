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
    
    $r->get('/')->to('Base#index');

    # Normal and secured routes to controller
    # $r->get('/')->to('Example#welcome');
    # $r->get('/upload_image')->to(controller => 'UploadImageController', action => 'index');
    $r->get('/service')->to('Base#login');
    my $auth = $r->under('/service')->to('Base#authCheck');
    $r->post('/service/login')->to('Base#loginValidate');


    $auth->get('/tips')->to('Base#showHelp');
    
    $auth->get('/clientstatus')->to('Views#clientsStatus');
    $auth->post('/clientstatus/list')->to('Views#clientsStatuslist');

    $auth->get('/issue')->to('Views#issuecert');
    $auth->post('/issue/upload')->to('Views#reqUpload');

    $auth->get('/reqs')->to('Views#reqFilesList');
    $auth->post('/reqs/list')->to('Views#reqsClientsListJson');
    $auth->post('/reqs/delete')->to('Views#reqClientsDelete');
    # They can be especially useful for manually matching file names with extensions, rather than using format detection.
    # /music/song.mp3 -> /music/#filename -> {filename => 'song.mp3'}
    $auth->get('/reqs/dl/#filename')->to('Views#reqClientsDownload');
    
    $auth->get('/certed')->to('Views#certedClientsList');
    $auth->post('/certed/list')->to('Views#certedClientsListJson');
    $auth->post('/certed/delete')->to('Views#certedClientsDelete');
    $auth->post('/certed/download')->to('Views#certedClientsDownload');
    $auth->get('/certed/dl/#filename')->to('Views#certedClientsDownload');
    
    
    ###### Other Urls ########
    # $r->get('/bar')->to('Foo#bar');
    $r->get('/bar')->to(controller => 'Foo', action => 'bar');

}

1;
