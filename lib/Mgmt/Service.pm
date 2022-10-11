package Mgmt::Service;
use Mojo::Base 'Mojolicious', -signatures;

# This method will run once at server start
sub startup ($self) {

    # Load configuration from config file
    my $config = $self->plugin('NotYAMLConfig');

    # Cron task to update the expire date
    $self->plugin(Cron => '0 1 * * *' => sub {
        print "Cron: update clients expire date.\n";
        my $file = '/opt/mgmt_service/vpntool/update-expiredate-cron.sh';
        my $result;
        if (-e $file){
            print "Running script to update exipredate.\n";
            $result = `bash $file`;
            print "$result\n";
        } else {
            print "Did not find expiredate update script. Skipp!!!!\n";
        }

    });

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
    $r->post('/service/logout')->to('Base#logout');


    $auth->get('/tips')->to('Base#showHelp');
    
    $auth->get('/clientstatus')->to('Views#clientsStatus');
    $auth->post('/clientstatus/list')->to('Views#clientsStatuslist');
    $auth->post('/clientstatus/update')->to('Views#clientStatusUpdate');


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
    
    
    ###### Other Urls test ########
    # $r->get('/bar')->to('Foo#bar');
    $r->get('/test')->to(controller => 'Test', action => 'test');
    $r->get('/welcome')->to('Example#welcome');


}

1;
