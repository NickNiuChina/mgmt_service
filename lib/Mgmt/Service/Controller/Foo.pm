# Controller
package Mgmt::Service::Controller::Foo;
use Mojo::Base 'Mojolicious::Controller', -signatures;

# Action
sub bar ($c) {
  my $name = $c->req->param('name');
  $c->res->headers->cache_control('max-age=1, no-cache');
  $c->render(json => {hello => $name});
}

1;
