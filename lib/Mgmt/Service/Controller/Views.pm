package Mgmt::Service::Controller::Views;
use Mojo::Base 'Mojolicious::Controller', -signatures;

# This action will render a template
sub clientsStatus ($c) {
   $c->render(template => 'contents/clientsStatus',msg => 'To be filled');
}

sub clientsStatuslist ($self) {
    use DBI;
    my $driver   = "Pg";
    my $database = "mgmtdb";
    my $dsn = "DBI:$driver:dbname=$database;host=127.0.0.1;port=5432";
    my $userid = "mgmt";
    my $password = "rootroot";
    my $dbh = DBI->connect($dsn, $userid, $password, { RaiseError => 1 }) or die $DBI::errstr;
    my $start = $self->req->body_params->param('start');
    my $draw = $self->req->body_params->param('draw'); 
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
    my $searchValue = $self->req->body_params->param('search[value]');
    # print $searchValue . "\n";
    if( $searchValue ne '' ) {
      $sql .= ' WHERE (';
      $sql .= 'storename LIKE ? OR cn LIKE ? or ip LIKE ?)';
      push @values, ('%'. $searchValue .'%','%'. $searchValue .'%','%'. $searchValue .'%');
    }
    my $sql_filter = $sql;
    my @values_filter = @values;
    # -- Ordering
    my $sortColumnId = $self->req->body_params->param('order[0][column]'); 
    my $sortColumnName = "";
    my $sortDir = "";
    if ( $sortColumnId ne '' ) {
        $sql .= ' ORDER BY ';
        $sortColumnName = $columns[$sortColumnId];
        my $sortDir = $self->req->body_params->param('order[0][dir]');
        $sql .= $sortColumnName . ' ' . $sortDir;
    }
    ## total rows
    my $s1th = $dbh->prepare('select count(*) from ovpnclients');
    $s1th->execute();
    my $count = $s1th->fetchrow_array();
    $s1th->finish;
    # Paging, get 'length' & 'start'
    my $limit = $self->req->body_params->param('length') || 10;
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
    print "SQL: $sql_filter\n";
    print "Arguments: @values_filter\n";
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
    $self->render(json => $output);
}

sub issuecert ($self) {
     # Render template "dir/name.html.ep" with message
        # $self->render(template => 'contents/issuecert', error => '', message => '');
        $self->stash( error   => $self->flash('error') );
        $self->stash( message => $self->flash('message') );
        $self->render(template => 'contents/issuecert');
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

sub reqFilesList ($self) {
    $self->render(template => 'contents/reqFileList',msg => 'To be filled');
}

sub certedClientsList ($self) {
    $self->render(template => 'contents/certFileList',msg => 'To be filled');
}

sub reqsClientsListJson ($self) {
  use File::Basename;
  use POSIX qw(strftime);
  # get the param first
  my $searchValue = $self->req->body_params->param('search[value]');
  my $sortColumnId = $self->req->body_params->param('order[0][column]');  # ignore now
  my $sortDir = $self->req->body_params->param('order[0][dir]');   # ignore now
  my $limit = $self->req->body_params->param('length') || 5;
  my $start = $self->req->body_params->param('start');
  my $draw = $self->req->body_params->param('draw'); 

  # 暂时不考率排序的问题
  # 分页也不考虑
  # 因为数据直接读取的文件目录文件，没有使用数据库

  my @filearray = ();
  my $file;

  # my $dir = $ENV{MGMTSERVICEDIR};
  my $dir = '/opt/reqs-done';
  

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

  for $file (@filesOrdered) {
      $createDate = strftime("%Y/%m/%d_%H:%M:%S", localtime((stat "$dir/$file")[10] ));
      # unshift @data, [$file, $createDate, 'NA', '<a> NA </a>'] ;
      unshift @data, [$file, $createDate, 'NA'] ;
  }

  my $output = {
        "draw" => $draw,
        "recordsTotal" => $count,
        "recordsFiltered" => $count,
        'data'  => \@data
  };
 
  $self->render(json => $output);

}

sub certedClientsListJson ($self) {
  use File::Basename;
  use POSIX qw(strftime);
  # get the param first
  my $searchValue = $self->req->body_params->param('search[value]');
  my $sortColumnId = $self->req->body_params->param('order[0][column]');  # ignore now
  my $sortDir = $self->req->body_params->param('order[0][dir]');   # ignore now
  my $limit = $self->req->body_params->param('length') || 5;
  my $start = $self->req->body_params->param('start');
  my $draw = $self->req->body_params->param('draw'); 

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
  }

  my $output = {
        "draw" => $draw,
        "recordsTotal" => $count,
        "recordsFiltered" => $count,
        'data'  => \@data
  };
  $self->render(json => $output);
}

sub reqClientsDelete ($c) {
    my $filename;
    my $result;
    # my $dir = $ENV{MGMTSERVICEDIR};
    my $dir = '/opt/reqs-done/';
    $filename = $c->param('filename');
    if ( $filename ) {
        print (" Client sent filename to be deleted: $filename\n");
        $result = {'result' => 'true'};
        my $file = $dir . $filename;
        unlink $file;
        print ($file . " deleted!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n");
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
        print (" Client sent filename to be deleted: $filename\n");
        $result = {'result' => 'true'};
        my $file = $dir . $filename;
        unlink $file;
        print ($file . " deleted!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n");
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
    print("\nClient request download file: $file\n\n");
    $c->res->headers->content_disposition("attachment; filename=$filename;");
    $c->reply->file($file);
}

sub certedClientsDownload ($c) {
    my $filename;
    my $result;  # for future
    # my $dir = $ENV{MGMTSERVICEDIR};
    my $dir = '/opt/validated/';
    $filename = $c->param('filename');
    my $file = $dir . $filename;
    print("\nClient request download file: $file\n\n");
    $c->res->headers->content_type('application/octet-stream');  # application/octet-stream          text/plain
    $c->res->headers->content_disposition("attachment; filename=$filename;"); 
    $c->reply->file($file);
}

1;
