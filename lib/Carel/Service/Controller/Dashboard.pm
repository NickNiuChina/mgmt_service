package Carel::Service::Controller::Dashboard;
use Mojo::Base 'Mojolicious::Controller', -signatures;

# This action will render a template
sub certedClientsList ($self) {

  # Render template "dir/name.html.ep" with message
  $self->render(template => 'contents/certFileList',msg => 'To be filled');
}

sub reqFilesList ($self) {
  #
  $self->render(template => 'contents/reqFileList',msg => 'To be filled');
}

sub certedClientsListJson ($self) {
  # get the param first
  my $searchValue = $self->req->body_params->param('search[value]');
  my $sortColumnId = $self->req->body_params->param('order[0][column]');
  my $sortDir = $self->req->body_params->param('order[0][dir]');
  my $limit = $self->req->body_params->param('length') || 5;
  my $start = $self->req->body_params->param('start');
  my $draw = $self->req->body_params->param('draw');

  # 暂时不考率排序的问题
  # 分页也不考虑
  # 因为数据直接读取的文件目录文件，没有使用数据库

  $self->render(
    json => {
        foo => [1, 'test', 3],
        start => $start,
        draw => $draw,
        limit => $limit,
        sortDir => $sortDir,
        sortColumnId => $sortColumnId,
        searchValue => $searchValue
      }
    );
}

# my %output = (
#        "draw" => $req->param('draw'),
#         "recordsTotal" => $limit,
#         "recordsFiltered" => $filterCount
#     );

1;
