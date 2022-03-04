package Carel::Service::Controller::Dashboard;
use Mojo::Base 'Mojolicious::Controller', -signatures;

# This action will render a template
sub certedClientsList ($self) {

  # Render template "dir/name.html.ep" with message
  $self->render(template => 'contents/certFileList',msg => 'To be filled');
}

sub reqFilesList ($self) {
  # Render template "base/base.html.ep" with message
  $self->render(template => 'contents/reqFileList',msg => 'To be filled');
}

1;
