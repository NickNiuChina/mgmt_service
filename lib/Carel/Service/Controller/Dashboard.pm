package Carel::Service::Controller::Dashboard;
use Mojo::Base 'Mojolicious::Controller', -signatures;

# This action will render a template
sub certedClientsList ($self) {

    # Render template "dir/name.html.ep" with message
    $self->render(template => 'contents/certFileList',msg => 'To be filled');
}

sub reqFilesList ($self) {
  #
  $self->render(template => 'contents/reqFileList', subTitle => ' | Req files');
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
  my $dir = $ENV{CARELSERVICEDIR};

  my @client_req_files = glob "$ENV{CARELSERVICEDIR}/*.req"; 
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
 
1;
