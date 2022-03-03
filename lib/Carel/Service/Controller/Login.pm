package Carel::Service::Controller::Login;
use Mojo::Base 'Mojolicious::Controller', -signatures;

# This action will render a template
sub index ($self) {

  # Render template "base/base.html.ep" with message
  $self->render(template => 'base/base',msg => 'To be filled');
}

1;
