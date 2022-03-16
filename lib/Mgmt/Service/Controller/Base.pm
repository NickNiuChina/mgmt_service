package Mgmt::Service::Controller::Base;
use Mojo::Base 'Mojolicious::Controller', -signatures;

# This action will render a template
sub index ($self) {

  # Render template "somedir/fn.html.ep" with message
  $self = shift;
  return $self->redirect_to('/service');
}

1;
