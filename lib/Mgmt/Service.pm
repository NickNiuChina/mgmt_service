package Mgmt::Service;
use Mojo::Base 'Mojolicious', -signatures;
use Mojo::Home;
use Data::Printer;

# This method will run once at server start
sub startup ($c) {

    # Load configuration from config file
    my $config = $c->plugin('NotYAMLConfig');

    my $home = Mojo::Home->new;
    $home->detect;
    chomp(my $filename = $config->{log}->{filename});

    # mojo log
    my $logfile;
    if ($config->{log}->{relative} eq 'yes') {
        $logfile = $home->child($filename);
    } else {
        $logfile = $config->{log}->{filename};
    }
    $config->{log}->{log_full_filename} = $logfile;
    $c->log( Mojo::Log->new( path => $logfile, level => 'trace' ) );
    

    # Cron task to update the expire date
    $c->plugin(
        Cron => '0 1 * * *' => sub {
            my $tms = shift;
            my $re;
            my $result;
            $re =`echo "Cron: update clients expire date." >> /var/log/mgmt.log`;
            my $file = '/opt/mgmt_service/vpntool/update-expiredate-cron.pl';
            my $filetun = '/opt/mgmt_service/vpntool/update-expiredate-tun-cron.pl';
            $re =`echo "Will run: /opt/mgmt_service/vpntool/update-expiredate-cron.pl" >> /var/log/mgmt.log`;
            $re =`echo "Will run: /opt/mgmt_service/vpntool/update-expiredate-tun-cron.pl" >> /var/log/mgmt.log`;
            if (-e $file){
                $re =`echo "[info]:Running script to update exipredate." >> /var/log/mgmt.log`;
                $result = `perl $file >> /var/log/mgmt.log 2>&1`;
                $re = `echo "$result\n" >> /var/log/mgmt.log`;
                # for tun server
                $result = `perl $filetun >> /var/log/mgmt.log 2>&1`;
                $re = `echo "$result\n" >> /var/log/mgmt.log`;
            } else {
                $re = `echo "[warn]:Did not find expiredate update script. Skipp!!!!" >> /var/log/mgmt.log`;
            }
        }
    );

    $c->plugin (I18N => {
        namespace => 'Mgmt::Service::I18N',
        support_url_langs => [qw(en zh)],
        # no_header_detect => 1
        }
    );
    
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
    $r->any(['GET', 'POST'] => '/service/logout')->to('Base#logout');
    

    $auth->get('/tips')->to('Base#showHelp');
    $auth->get('/language')->to(controller => 'Views', action => 'setLanguage');    
    
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
    
    #### Add tun mode openvpn server ###############################
    $auth->get('/tunclientstatus')->to('Views#tunClientsStatus');
    $auth->post('/tunclientstatus/list')->to('Views#tunClientsStatuslist');
    $auth->post('/tunclientstatus/update')->to('Views#tunClientStatusUpdate');

    $auth->get('/tunissue')->to('Views#tunIssueCert');
    $auth->post('/tunissue/upload')->to('Views#tunReqUpload');

    $auth->get('/tungenericissue')->to('Views#tunGenericIssueCert');
    $auth->post('/tungenericissue/generate')->to('Views#tunGenericIssueCertGenerate');

    $auth->get('/tunreqs')->to('Views#tunReqFilesList');
    $auth->post('/tunreqs/list')->to('Views#tunReqsClientsListJson');
    $auth->post('/tunreqs/delete')->to('Views#tunReqClientsDelete');
    # They can be especially useful for manually matching file names with extensions, rather than using format detection.
    # /music/song.mp3 -> /music/#filename -> {filename => 'song.mp3'}
    $auth->get('/tunreqs/dl/#filename')->to('Views#tunReqClientsDownload');
    
    $auth->get('/tuncerted')->to('Views#tunCertedClientsList');
    $auth->post('/tuncerted/list')->to('Views#tunCertedClientsListJson');
    $auth->post('/tuncerted/delete')->to('Views#tunCertedClientsDelete');
    $auth->post('/tuncerted/download')->to('Views#tunCertedClientsDownload');
    $auth->get('/tuncerted/dl/#filename')->to('Views#tunCertedClientsDownload');

    $auth->get('/tungenericcerted')->to('Views#tunGenericCertedClientsList');
    $auth->post('/tungenericcerted/list')->to('Views#tunGenericCertedClientsListJson');
    $auth->post('/tungenericcerted/delete')->to('Views#tunGenericCertedClientsDelete');
    $auth->post('/tungenericcerted/download')->to('Views#tunGenericCertedClientsDownload');
    $auth->get('/tungenericcerted/dl/#filename')->to('Views#tunGenericCertedClientsDownload');
    
    # Secret info pages
    $auth->get('/system/session')->to('Views#sysSession');
    $auth->get('/system/appConfig')->to('Views#sysAppConfig');
    $auth->get('/system/appAttr')->to('Views#sysAppAttr');

    ###### Other Urls test ########
    # $r->get('/bar')->to('Foo#bar');
    $r->get('/test')->to(controller => 'Test', action => 'test');
    $r->get('/welcome')->to('Example#welcome');

}

1;
