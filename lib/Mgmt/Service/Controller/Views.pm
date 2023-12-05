package Mgmt::Service::Controller::Views;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use Data::Printer;
use Mgmt::Service::DB;
use DBI;

# change language
sub setLanguage ($self) {
    # p $self->config->{users};
    # $self->languages('en');
    # p $self->languages;
    # p $self->param('language');

    # new language
    my $nl = $self->param('language');

    # p $self->req->headers->referrer;
    my $language = $self->config->{supported_languages};

    my %lh = map {$_ => 1} @$language;
    
    if (exists $lh{$nl}) {
        $self->languages($nl);
        $self->session(lang => $nl);  
        $self->config->{current_language} = $nl;
        $self->redirect_to($self->req->headers->referrer);
    }
    else {
        $self->flash( error => 'New language is not supported!' );
        $self->redirect_to($self->req->headers->referrer);
    }
}

# This action will render a template
sub clientsStatus ($c) {
   $c->render(template => 'contents/clientsStatus',msg => 'To be filled');
}

sub clientsStatuslist ($c) {
    # print "#######debug##########################\n";
    #  p $c->req;
    #  p $c->tx;
    # p $c;
    my $config = $c->config;
    # p ($config);
    # say ($config->{db}->{dbname});

    my $dbh = Mgmt::Service::DB->connect($c);
    # p $dbh;
    my $start = $c->req->body_params->param('start');
    my $draw = $c->req->body_params->param('draw'); 
    my $table ="ovpnclients";
    my @fields;
    my @Data;
    my $iFilteredTotal;
    my $iTotal;
    my @values;
    my @columns = qw/storename cn ip changedate expiredate status/;
    my $sql = "SELECT storename, cn, ip, changedate, expiredate, status from ovpnclients";
    #SQL_CALC_FOUND_ROWS, it is possible to use this mothed to count the rows.
    # -- Filtering
    my $searchValue = $c->req->body_params->param('search[value]');
    # print $searchValue . "\n";
    if( $searchValue ne '' ) {
      $sql .= ' WHERE (';
      $sql .= 'storename LIKE ? OR cn LIKE ? or ip LIKE ?)';
      push @values, ('%'. $searchValue .'%','%'. $searchValue .'%','%'. $searchValue .'%');
    }
    my $sql_filter = $sql;
    my @values_filter = @values;
    # -- Ordering
    my $sortColumnId = $c->req->body_params->param('order[0][column]'); 
    my $sortColumnName = "";
    my $sortDir = "";
    if ( $sortColumnId ne '' ) {
        $sql .= ' ORDER BY ';
        $sortColumnName = $columns[$sortColumnId];
        my $sortDir = $c->req->body_params->param('order[0][dir]');
        $sql .= $sortColumnName . ' ' . $sortDir;
    }
    ## total rows
    my $s1th = $dbh->prepare('select count(*) from ovpnclients');
    $s1th->execute();
    my $count = $s1th->fetchrow_array();
    $s1th->finish;
    # Paging, get 'length' & 'start'
    my $limit = $c->req->body_params->param('length') || 10;
    if ($limit == -1) {
        $limit = $count;
    }
    my $offset="0";
    if($start) {
      $offset = $start;
    }
      $sql .= " LIMIT ? OFFSET ? ";
      push @values, $limit;
      push @values, $offset;
    #*************************************
    # debug
    $c->log->info("SQL: $sql_filter");
    $c->log->info("Arguments: @values_filter");
    my $sth1 = $dbh->prepare($sql_filter);
    $sth1->execute(@values_filter);
    my $filterCount = $sth1->rows;
    $sth1->finish;
    ## rows after filter*******************
    my $sth = $dbh->prepare($sql);
    $sth->execute(@values);
    # output hashref
    my $output = {
        "draw" => $draw,
        "recordsTotal" => $count,
        "recordsFiltered" => $filterCount
    };

    my $rowcount = 0;
    my $dataElement = "";
    # fetching the different rows data.
    while(my @aRow = $sth->fetchrow_array) {
            my @row = ();
                for (my $i = 0; $i < @columns; $i++) {
                # looping thru different columns, pushing data to an array.
                $dataElement = "";
                $dataElement = $aRow[$i];
                push @row, $dataElement;          
            }
            push @row, $rowcount;
            # add each row data to hash collection.
            $output->{'data'}[$rowcount] = [@row];
            $rowcount++;
    }
    unless($rowcount) {
        $output->{'data'} = ''; #we don't want to have 'null'. will break js
    }
    $sth->finish();
    $dbh->disconnect();
    # p $output;
    $c->render(json => $output);
}

sub clientStatusUpdate ($c) {

    my $dbh = Mgmt::Service::DB->connect($c);

    my $newstorename;
    my $result;
    my $cn;
    $cn = $c->param('cn');
    $newstorename = $c->param('newstorename');
        $c->log->info("I saw filename: $cn");
        $c->log->info("I saw newstorename: $newstorename");
    if ( $cn ) {
        $c->log->info("I saw \$filename: $cn");
        $c->log->info("I saw newstorename: $newstorename");
        my $sql = "update ovpnclients set storename= ? where cn= ?";
        my @values = ($newstorename, $cn);
        my $sth = $dbh->prepare($sql);
        $sth->execute(@values);
        $sth->finish;
        $dbh->disconnect;
        $c->log->info("$sql, @values");
        $c->log->info("Sql done!");
        $result = {'result' => 'true'};
        $c->render(json => $result);
    }
    else{
      $result = {'result' => 'false'};
      $c->render(json => $result);
    }
}

sub issuecert ($c) {
    # Render template "dir/name.html.ep" with message
    # $c->render(template => 'contents/issuecert', error => '', message => '');
    $c->stash( error   => $c->flash('error') );
    $c->stash( message => $c->flash('message') );
    $c->render(template => 'contents/issuecert');
}

sub reqUpload ($c) {
 
    my ( $req, $req_file );
    if ( !$c->param('upload_req') ) {
        $c->flash( error => 'REQ file is required.' );
        $c->redirect_to('/service/issue');
    }

    # Check for Valid Extension in case of choosing other files
    my $reqFilename = $c->param('upload_req')->filename ;
    if ( $reqFilename !~ /\.req$/ ) {
        $c->flash( error => 'Invalid req file extension. Please check!' );
        return $c->redirect_to('/service/issue');
    }
    if (length($reqFilename) != 40) {
      $c->flash( error => 'Invalid req filename length. Please check!' );
      return $c->redirect_to('/service/issue');
    }

    # Upload the req file
    $req = $c->req->upload('upload_req');

    $req_file = '/opt/reqs/' . $c->param('upload_req')->filename;
    
    # debug
    # print "HHHHHHHHHHHHHHHHHHHHHHHHHH: " . $c->param('upload_req')->filename . "\n";
    $req->move_to($req_file);
    my $result = `bash /opt/mgmt_service/vpntool/generate-requests.sh`; # SELFDEFINEDSUCCESS
    if ( $result =~ /SELFDEFINEDSUCCESS/m ) {
        $c->flash( message => 'Req file Uploaded sucessfully.' );
        $c->redirect_to('/service/issue');
    } else {
        $c->flash( error => 'Something wrong during generating cert file.' );
	      $c->redirect_to('/service/issue');
    }
}

sub reqFilesList ($c) {
    $c->render(template => 'contents/reqFileList',msg => 'To be filled');
}

sub certedClientsList ($c) {
    $c->render(template => 'contents/certFileList',msg => 'To be filled');
}

sub reqsClientsListJson ($c) {
    use File::Basename;
    use POSIX qw(strftime);
    # get the param first
    my $searchValue = $c->req->body_params->param('search[value]');
    my $sortColumnId = $c->req->body_params->param('order[0][column]');  # ignore now
    my $sortDir = $c->req->body_params->param('order[0][dir]');   # ignore now
    my $limit = $c->req->body_params->param('length') || 5;
    my $start = $c->req->body_params->param('start');
    my $draw = $c->req->body_params->param('draw'); 

    # 暂时不考率排序的问题
    # 分页也不考虑
    # 因为数据直接读取的文件目录文件，没有使用数据库

    my @filearray = ();
    my $file;

    # my $dir = $ENV{MGMTSERVICEDIR};
    my $dir = '/opt/reqs-done';
    my $cert_dir = '/opt/easyrsa-all';
  

    my @client_req_files = glob "$dir/*.req"; 
    for my $file (@client_req_files) {
      my $filename = basename($file);
      next unless (length($filename) == 40);
      if ( $searchValue) {
        next unless $filename =~ /$searchValue/;
      }
      unshift @filearray, $filename;
    }

    # ordering by file name
    my @filesOrdered = reverse sort {$a cmp $b} @filearray;
    my $count = @filesOrdered;


    my @data;
    my $temp = [];
    my $createDate;
    my $expireDate;

    for $file (@filesOrdered) {
        $createDate = strftime("%Y/%m/%d_%H:%M:%S", localtime((stat "$dir/$file")[10] ));
        # unshift @data, [$file, $createDate, 'NA', '<a> NA </a>'] ;
        # $expireDate = 'NA' if $@;
        unshift @data, [$file, $createDate, 'NA'] ;
    }

    my $output = {
        "draw" => $draw,
        "recordsTotal" => $count,
        "recordsFiltered" => $count,
        'data'  => \@data
    };
 
    $c->render(json => $output);

}

sub certedClientsListJson ($c) {
  use File::Basename;
  use POSIX qw(strftime);
  # get the param first
  my $searchValue = $c->req->body_params->param('search[value]');
  my $sortColumnId = $c->req->body_params->param('order[0][column]');  # ignore now
  my $sortDir = $c->req->body_params->param('order[0][dir]');   # ignore now
  my $limit = $c->req->body_params->param('length') || 5;
  my $start = $c->req->body_params->param('start');
  my $draw = $c->req->body_params->param('draw'); 

  # 暂时不考率排序的问题
  # 分页也不考虑
  # 因为数据直接读取的文件目录文件，没有使用数据库

  my @filearray = ();
  my $file;

  # my $dir = $ENV{MGMTSERVICEDIR};
  my $dir = '/opt/validated';
  

  my @client_req_files = glob "$dir/*.p7mb64"; 
  for my $file (@client_req_files) {
    my $filename = basename($file);
    next unless (length($filename) == 43);
    if ( $searchValue) {
      next unless $filename =~ /$searchValue/;
    }
    unshift @filearray, $filename;
  }

  # ordering by file name
  my @filesOrdered = reverse sort {$a cmp $b} @filearray;
  my $count = @filesOrdered;


  my @data;
  my $temp = [];
  my $createDate;

  for $file (@filesOrdered) {
      $createDate = strftime("%Y/%m/%d_%H:%M:%S", localtime((stat "$dir/$file")[10] ));
      unshift @data, [$file, $createDate, 'NA'] ;
      # print "I saw \$file: $file \n";
  }

  my $output = {
        "draw" => $draw,
        "recordsTotal" => $count,
        "recordsFiltered" => $count,
        'data'  => \@data
  };
  $c->render(json => $output);
}

sub reqClientsDelete ($c) {
    my $filename;
    my $result;
    # my $dir = $ENV{MGMTSERVICEDIR};
    my $dir = '/opt/tun-ovpn-files/reqs-done/';
    $filename = $c->param('filename');
    if ( $filename ) {
        $c->log->info(" Client sent filename to be deleted: $filename");
        $result = {'result' => 'true'};
        my $file = $dir . $filename;
        unlink $file;
        $c->log->info($file . " deleted!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
        $c->render(json => $result);
    }
    else{
      $result = {'result' => 'false'};
      $c->render(json => $result);
    }
  # $c->redirect_to('/service/certed');
}

sub certedClientsDelete ($c) {
    my $filename;
    my $result;
    # my $dir = $ENV{MGMTSERVICEDIR};
    my $dir = '/opt/validated/';
    $filename = $c->param('filename');
    if ( $filename ) {
        $c->log->info(" Client sent filename to be deleted: $filename");
        $result = {'result' => 'true'};
        my $file = $dir . $filename;
        unlink $file;
        $c->log->info($file . " deleted!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
        $c->render(json => $result);
    }
    else{
      $result = {'result' => 'false'};
      $c->render(json => $result);
    }
  # $c->redirect_to('/service/certed');
}

# reqs/client files download

sub reqClientsDownload ($c) {
    my $filename;
    my $result;  # for future
    # my $dir = $ENV{MGMTSERVICEDIR};
    my $dir = '/opt/reqs-done/';
    $filename = $c->param('filename');
    my $file = $dir . $filename;
    $c->log->info("\nClient request download file: $file");
    $c->res->headers->content_disposition("attachment; filename=$filename;");
    $c->reply->file($file);
    $c->log->info("Send download file done");
}

sub certedClientsDownload ($c) {
    my $filename;
    my $result;  # for future
    # my $dir = $ENV{MGMTSERVICEDIR};
    my $dir = '/opt/validated/';
    $filename = $c->param('filename');
    my $file = $dir . $filename;
    $c->log->info("Client request download file: $file");
    $c->res->headers->content_type('application/octet-stream');  # application/octet-stream          text/plain
    $c->res->headers->content_disposition("attachment; filename=$filename;"); 
    $c->reply->file($file);
    $c->log->info("Send download file done");
}

# *** Add tun mode openvpn server  *****************************************************************************************************************
sub tunClientsStatus ($c) {
   $c->render(template => 'contents/tunclientsStatus',msg => 'To be filled');
}

sub tunClientsStatuslist ($c) {
    my $config = $c->config;
    my $dbh = Mgmt::Service::DB->connect($c);
    # p $dbh;
    my $start = $c->req->body_params->param('start');
    my $draw = $c->req->body_params->param('draw'); 
    my $table ="tunovpnclients";
    my @fields;
    my @Data;
    my $iFilteredTotal;
    my $iTotal;
    my @values;
    my @columns = qw/storename cn ip changedate expiredate status/;
    my $sql = "SELECT storename, cn, ip, changedate, expiredate, status from tunovpnclients";
    #SQL_CALC_FOUND_ROWS, it is possible to use this mothed to count the rows.
    # -- Filtering
    my $searchValue = $c->req->body_params->param('search[value]');
    # print $searchValue . "\n";
    if( $searchValue ne '' ) {
      $sql .= ' WHERE (';
      $sql .= 'storename LIKE ? OR cn LIKE ? or ip LIKE ?)';
      push @values, ('%'. $searchValue .'%','%'. $searchValue .'%','%'. $searchValue .'%');
    }
    my $sql_filter = $sql;
    my @values_filter = @values;
    # -- Ordering
    my $sortColumnId = $c->req->body_params->param('order[0][column]'); 
    my $sortColumnName = "";
    my $sortDir = "";
    if ( $sortColumnId ne '' ) {
        $sql .= ' ORDER BY ';
        $sortColumnName = $columns[$sortColumnId];
        my $sortDir = $c->req->body_params->param('order[0][dir]');
        $sql .= $sortColumnName . ' ' . $sortDir;
    }
    ## total rows
    my $s1th = $dbh->prepare('select count(*) from tunovpnclients');
    $s1th->execute();
    my $count = $s1th->fetchrow_array();
    $s1th->finish;
    # Paging, get 'length' & 'start'
    my $limit = $c->req->body_params->param('length') || 10;
    if ($limit == -1) {
        $limit = $count;
    }
    my $offset="0";
    if($start) {
      $offset = $start;
    }
      $sql .= " LIMIT ? OFFSET ? ";
      push @values, $limit;
      push @values, $offset;
    #*************************************
    # debug
    $c->log->info("SQL: $sql");
    $c->log->info("Arguments: @values_filter");
    my $sth1 = $dbh->prepare($sql_filter);
    $sth1->execute(@values_filter);
    my $filterCount = $sth1->rows;
    $sth1->finish;
    ## rows after filter*******************
    my $sth = $dbh->prepare($sql);
    $sth->execute(@values);
    # output hashref
    my $output = {
        "draw" => $draw,
        "recordsTotal" => $count,
        "recordsFiltered" => $filterCount
    };

    my $rowcount = 0;
    my $dataElement = "";
    # fetching the different rows data.
    while(my @aRow = $sth->fetchrow_array) {
            my @row = ();
                for (my $i = 0; $i < @columns; $i++) {
                # looping thru different columns, pushing data to an array.
                $dataElement = "";
                $dataElement = $aRow[$i];
                push @row, $dataElement;          
            }
            push @row, $rowcount;
            # add each row data to hash collection.
            $output->{'data'}[$rowcount] = [@row];
            $rowcount++;
    }
    unless($rowcount) {
        $output->{'data'} = ''; #we don't want to have 'null'. will break js
    }
    $sth->finish();
    $dbh->disconnect();
    # p $output;
    $c->render(json => $output);
}

sub tunClientStatusUpdate ($c) {

    my $dbh = Mgmt::Service::DB->connect($c);

    my $newstorename;
    my $result;
    my $cn;
    $cn = $c->param('cn');
    $newstorename = $c->param('newstorename');
        $c->log->info("I saw filename: $cn");
        $c->log->info("I saw newstorename: $newstorename");
    if ( $cn ) {
        $c->log->info("I saw \$filename: $cn");
        $c->log->info("I saw newstorename: $newstorename");
        my $sql = "update tunovpnclients set storename= ? where cn= ?";
        my @values = ($newstorename, $cn);
        my $sth = $dbh->prepare($sql);
        $sth->execute(@values);
        $sth->finish;
        $dbh->disconnect;
        $c->log->info("$sql, @values");
        $c->log->info("Sql done!");
        $result = {'result' => 'true'};
        $c->render(json => $result);
    }
    else{
      $result = {'result' => 'false'};
      $c->render(json => $result);
    }
}

sub tunIssueCert ($c) {
    # Render template "dir/name.html.ep" with message
    # $c->render(template => 'contents/issuecert', error => '', message => '');
    $c->stash( error   => $c->flash('error') );
    $c->stash( message => $c->flash('message') );
    $c->render(template => 'contents/tunissuecert');
}

sub tunGenericIssueCert ($c) {
    # Render template "dir/name.html.ep" with message
    # $c->render(template => 'contents/issuecert', error => '', message => '');
    $c->stash( error   => $c->flash('error') );
    $c->stash( message => $c->flash('message') );
    $c->render(template => 'contents/tungenericissuecert');
}

sub tunGenericIssueCertGenerate ($c) {
    my $cn;
    if ( !$c->param('new_cn') ) {
        $c->flash( error => 'new cn name is required.' );
        $c->redirect_to('/service/tungenericissue');
    }

    $cn = $c->param('new_cn');
    chomp $cn;
    $cn =~ s/\s+$//;
    $cn =~ s/^\s+//;
    my $dir = '/opt/tun-ovpn-files/generic-ovpn/';
    my $cnZip = $dir . $cn . '.zip';
    $c->log->info("Requested to generate new cn for generic clients: |$cn|");
    $c->log->info("Check if zip existed: $cnZip");
    
    unless ( $cn =~ /^[A-z0-9-_]*$/ ){
        $c->flash( error => "Special character is illegal: New cn: $cn" );
        $c->redirect_to('/service/tungenericissue');
    } 
    # check if there is special character
    
    if ( -e $cnZip){
        $c->flash( error => "This cn already existed: New cn: $cn" );
        $c->redirect_to('/service/tungenericissue');
    } 
    else
    {
        $c->flash( message => "这个功能还在开发中\nNew cn: $cn" );
        $c->redirect_to('/service/tungenericissue');
    }
}

sub tunReqUpload ($c) {
 
    my ( $req, $req_file );
    if ( !$c->param('upload_req') ) {
        $c->flash( error => 'REQ file is required.' );
        $c->redirect_to('/service/tunissue');
    }

    # Check for Valid Extension in case of choosing other files
    my $reqFilename = $c->param('upload_req')->filename ;
    if ( $reqFilename !~ /\.req$/ ) {
        $c->flash( error => 'Invalid req file extension. Please check!' );
        return $c->redirect_to('/service/tunissue');
    }
    if (length($reqFilename) != 40) {
      $c->flash( error => 'Invalid req filename length. Please check!' );
      return $c->redirect_to('/service/tunissue');
    }

    # Upload the req file
    $req = $c->req->upload('upload_req');

    $req_file = '/opt/tun-ovpn-files/reqs/' . $c->param('upload_req')->filename;
    
    # debug
    # print "HHHHHHHHHHHHHHHHHHHHHHHHHH: " . $c->param('upload_req')->filename . "\n";
    $req->move_to($req_file);
    my $result = `bash /opt/mgmt_service/vpntool/generate-requests-tun.sh`; # SELFDEFINEDSUCCESS
    if ( $result =~ /SELFDEFINEDSUCCESS/m ) {
        $c->flash( message => 'Req file Uploaded sucessfully.' );
        $c->redirect_to('/service/tunissue');
    } else {
        $c->flash( error => 'Something wrong during generating cert file.' );
	      $c->redirect_to('/service/tunissue');
    }
}

sub tunReqFilesList ($c) {
    $c->render(template => 'contents/tunReqFileList',msg => 'To be filled');
}


sub tunReqsClientsListJson ($c) {
    use File::Basename;
    use POSIX qw(strftime);
    # get the param first
    my $searchValue = $c->req->body_params->param('search[value]');
    my $sortColumnId = $c->req->body_params->param('order[0][column]');  # ignore now
    my $sortDir = $c->req->body_params->param('order[0][dir]');   # ignore now
    my $limit = $c->req->body_params->param('length') || 5;
    my $start = $c->req->body_params->param('start');
    my $draw = $c->req->body_params->param('draw'); 

    # 暂时不考率排序的问题
    # 分页也不考虑
    # 因为数据直接读取的文件目录文件，没有使用数据库

    my @filearray = ();
    my $file;

    # my $dir = $ENV{MGMTSERVICEDIR};
    my $dir = '/opt/tun-ovpn-files/reqs-done';
    my $cert_dir = '/opt/tun-ovpn-files/easyrsa-tcp';
  

    my @client_req_files = glob "$dir/*.req"; 
    for my $file (@client_req_files) {
      my $filename = basename($file);
      next unless (length($filename) == 40);
      if ( $searchValue) {
        next unless $filename =~ /$searchValue/;
      }
      unshift @filearray, $filename;
    }

    # ordering by file name
    my @filesOrdered = reverse sort {$a cmp $b} @filearray;
    my $count = @filesOrdered;


    my @data;
    my $temp = [];
    my $createDate;
    my $expireDate;

    for $file (@filesOrdered) {
        $createDate = strftime("%Y/%m/%d_%H:%M:%S", localtime((stat "$dir/$file")[10] ));
        # unshift @data, [$file, $createDate, 'NA', '<a> NA </a>'] ;
        # $expireDate = 'NA' if $@;
        unshift @data, [$file, $createDate, 'NA'] ;
    }

    my $output = {
        "draw" => $draw,
        "recordsTotal" => $count,
        "recordsFiltered" => $count,
        'data'  => \@data
    };
 
    $c->render(json => $output);

}


sub tunReqClientsDelete ($c) {
    my $filename;
    my $result;
    # my $dir = $ENV{MGMTSERVICEDIR};
    my $dir = '/opt/tun-ovpn-files/reqs-done/';
    $filename = $c->param('filename');
    if ( $filename ) {
        $c->log->info(" Client sent filename to be deleted: $filename");
        $result = {'result' => 'true'};
        my $file = $dir . $filename;
        unlink $file;
        $c->log->info($file . " deleted!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
        $c->render(json => $result);
    }
    else{
      $result = {'result' => 'false'};
      $c->render(json => $result);
    }
  # $c->redirect_to('/service/certed');
}

sub tunreqClientsDownload ($c) {
    my $filename;
    my $result;  # for future
    # my $dir = $ENV{MGMTSERVICEDIR};
    my $dir = '/opt/tun-ovpn-files/reqs-done/';
    $filename = $c->param('filename');
    my $file = $dir . $filename;
    $c->log->info("\nClient request download file: $file");
    $c->res->headers->content_disposition("attachment; filename=$filename;");
    $c->reply->file($file);
    $c->log->info("Send download file done");
}

# ---------------------------------------------------------------------

sub tunCertedClientsList ($c) {
    $c->render(template => 'contents/tunCertFileList',msg => 'To be filled');
}

sub tunCertedClientsListJson ($c) {
    use File::Basename;
    use POSIX qw(strftime);
    # get the param first
    my $searchValue = $c->req->body_params->param('search[value]');
    my $sortColumnId = $c->req->body_params->param('order[0][column]');  # ignore now
    my $sortDir = $c->req->body_params->param('order[0][dir]');   # ignore now
    my $limit = $c->req->body_params->param('length') || 5;
    my $start = $c->req->body_params->param('start');
    my $draw = $c->req->body_params->param('draw'); 

    # 暂时不考率排序的问题
    # 分页也不考虑
    # 因为数据直接读取的文件目录文件，没有使用数据库

    my @filearray = ();
    my $file;

    # my $dir = $ENV{MGMTSERVICEDIR};
    my $dir = '/opt/tun-ovpn-files/validated';


    my @client_req_files = glob "$dir/*.p7mb64"; 
    for my $file (@client_req_files) {
      my $filename = basename($file);
      next unless (length($filename) == 43);
      if ( $searchValue) {
        next unless $filename =~ /$searchValue/;
      }
      unshift @filearray, $filename;
    }

    # ordering by file name
    my @filesOrdered = reverse sort {$a cmp $b} @filearray;
    my $count = @filesOrdered;


    my @data;
    my $temp = [];
    my $createDate;

    for $file (@filesOrdered) {
        $createDate = strftime("%Y/%m/%d_%H:%M:%S", localtime((stat "$dir/$file")[10] ));
        unshift @data, [$file, $createDate, 'NA'] ;
        # print "I saw \$file: $file \n";
    }

    my $output = {
          "draw" => $draw,
          "recordsTotal" => $count,
          "recordsFiltered" => $count,
          'data'  => \@data
    };
    $c->render(json => $output);
}

sub tunCertedClientsDelete ($c) {
    my $filename;
    my $result;
    # my $dir = $ENV{MGMTSERVICEDIR};
    my $dir = '/opt/tun-ovpn-files/validated/';
    $filename = $c->param('filename');
    if ( $filename ) {
        $c->log->info(" Client sent filename to be deleted: $filename");
        $result = {'result' => 'true'};
        my $file = $dir . $filename;
        unlink $file;
        $c->log->info($file . " deleted!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
        $c->render(json => $result);
    }
    else{
      $result = {'result' => 'false'};
      $c->render(json => $result);
    }
}

sub tunCertedClientsDownload ($c) {
    my $filename;
    my $result;  # for future
    # my $dir = $ENV{MGMTSERVICEDIR};
    my $dir = '/opt/tun-ovpn-files/validated/';
    $filename = $c->param('filename');
    my $file = $dir . $filename;
    $c->log->info("Client request download file: $file");
    $c->res->headers->content_type('application/octet-stream');  # application/octet-stream          text/plain
    $c->res->headers->content_disposition("attachment; filename=$filename;"); 
    $c->reply->file($file);
    $c->log->info("Send download file done");
}

sub tunGenericCertedClientsList ($c) {
    $c->render(template => 'contents/tunGenericCertFileList',msg => 'To be filled');
}

sub tunGenericCertedClientsListJson ($c) {
    use File::Basename;
    use POSIX qw(strftime);
    # get the param first
    my $searchValue = $c->req->body_params->param('search[value]');
    my $sortColumnId = $c->req->body_params->param('order[0][column]');  # ignore now
    my $sortDir = $c->req->body_params->param('order[0][dir]');   # ignore now
    my $limit = $c->req->body_params->param('length') || 5;
    my $start = $c->req->body_params->param('start');
    my $draw = $c->req->body_params->param('draw'); 

    # 暂时不考率排序的问题
    # 分页也不考虑
    # 因为数据直接读取的文件目录文件，没有使用数据库

    my @filearray = ();
    my $file;

    # my $dir = $ENV{MGMTSERVICEDIR};
    my $dir = '/opt/tun-ovpn-files/generic-ovpn';


    my @client_req_files = glob "$dir/*.zip"; 
    for my $file (@client_req_files) {
      my $filename = basename($file);
    #   next unless (length($filename) == 43);
      if ( $searchValue) {
        next unless $filename =~ /$searchValue/;
      }
      unshift @filearray, $filename;
    }

    # ordering by file name
    my @filesOrdered = reverse sort {$a cmp $b} @filearray;
    my $count = @filesOrdered;


    my @data;
    my $temp = [];
    my $createDate;

    for $file (@filesOrdered) {
        $createDate = strftime("%Y/%m/%d_%H:%M:%S", localtime((stat "$dir/$file")[10] ));
        unshift @data, [$file, $createDate, 'NA'] ;
        # print "I saw \$file: $file \n";
    }

    my $output = {
          "draw" => $draw,
          "recordsTotal" => $count,
          "recordsFiltered" => $count,
          'data'  => \@data
    };
    $c->render(json => $output);
}

sub tunGenericCertedClientsDelete ($c) {
    my $filename;
    my $result;
    # my $dir = $ENV{MGMTSERVICEDIR};
    my $dir = '/opt/tun-ovpn-files/generic-ovpn/';
    $filename = $c->param('filename');
    if ( $filename ) {
        $c->log->info(" Client sent filename to be deleted: $filename");
        $result = {'result' => 'true'};
        my $file = $dir . $filename;
        unlink $file;
        $c->log->info($file . " deleted!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
        $c->render(json => $result);
    }
    else{
      $result = {'result' => 'false'};
      $c->render(json => $result);
    }
}

sub tunGenericCertedClientsDownload ($c) {
    my $filename;
    my $result;  # for future
    # my $dir = $ENV{MGMTSERVICEDIR};
    my $dir = '/opt/tun-ovpn-files/generic-ovpn/';
    $filename = $c->param('filename');
    my $file = $dir . $filename;
    $c->log->info("Client request download file: $file");
    $c->res->headers->content_type('application/octet-stream');  # application/octet-stream          text/plain
    $c->res->headers->content_disposition("attachment; filename=$filename;"); 
    $c->reply->file($file);
    $c->log->info("Send download file done");
}

# *** Add tun mode openvpn server  *****************************************************************************************************************

# Secret page views

sub sysSession ($self) {
    # p $self->session;
    my $session = $self->session;
    $self->render(json => $session);
}

sub sysAppConfig ($self) {
    # p $self->config;
    my $config = $self->config;
    $self->render(json => $config);
}

sub sysAppAttr ($self) {
    # p $self;
    $self->render(json => np $self);
}

1;
