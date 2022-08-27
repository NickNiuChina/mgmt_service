# Controller
package Mgmt::Service::Controller::Test;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use Mojo::Home;

# Action
sub test ($c) {
  my $name = $c->req->param('name');
  my $home = Mojo::Home->new;
  $c->res->headers->cache_control('max-age=1, no-cache');
  $c->render(
    json => {hello => $name, 
    MojoHome => $home }
  );
}

1;
