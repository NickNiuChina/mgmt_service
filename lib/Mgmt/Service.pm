package Mgmt::Service;
use Mojo::Base 'Mojolicious', -signatures;
use Data::Printer;

# This method will run once at server start
sub startup ($c) {

    # Load configuration from config file
    my $config = $c->plugin('NotYAMLConfig');

    # Cron task to update the expire date
    $c->plugin(Cron => '0 1 * * *' => sub {
        my $tms = shift;
        my $re;
        $re =`echo "Cron: update clients expire date." >> /var/log/mgmt.log`;
        my $file = '/opt/mgmt_service/vpntool/update-expiredate-cron.pl';
        $re =`echo "Will run: /opt/mgmt_service/vpntool/update-expiredate-cron.pl" >> /var/log/mgmt.log`;
        my $result;
        if (-e $file){
            $re =`echo "[info]:Running script to update exipredate." >> /var/log/mgmt.log`;
            $result = `perl $file >> /var/log/mgmt.log 2>&1`;
            $re = `echo "$result\n" >> /var/log/mgmt.log`;
        } else {
            $re = `echo "[warn]:Did not find expiredate update script. Skipp!!!!" >> /var/log/mgmt.log`;
        }
    });
    
    # mojo log
    $c->log( Mojo::Log->new( path => '/var/log/mgmt.log', level => 'trace' ) );
    
    # Configure the application
    $c->secrets($config->{secrets});

    # Router
    my $r = $c->routes;
    
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
