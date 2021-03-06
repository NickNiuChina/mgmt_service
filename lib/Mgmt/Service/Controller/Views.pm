package Mgmt::Service::Controller::Views;
use Mojo::Base 'Mojolicious::Controller', -signatures;

# This action will render a template
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

  # ??????????????????????????????
  # ??????????????????
  # ?????????????????????????????????????????????????????????????????????

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
      unshift @data, [$file, $createDate, 'NA', '<a> NA </a>'] ;
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

  # ??????????????????????????????
  # ??????????????????
  # ?????????????????????????????????????????????????????????????????????

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
      unshift @data, [$file, $createDate, 'NA', '<a> NA </a>'] ;
  }

  my $output = {
        "draw" => $draw,
        "recordsTotal" => $count,
        "recordsFiltered" => $count,
        'data'  => \@data
  };
 
  $self->render(json => $output);

}
 
1;
