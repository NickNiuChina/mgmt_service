# Controller
package Mgmt::Service::Controller::Test;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use Mojo::Home;

# Action
sub test ($c) {
  # get params name
  my $name = $c->req->param('name'); 
  my $home = Mojo::Home->new;
  opendir(DIR, $home) or die "can't open $home: $!";
  my @files = readdir DIR;
  closedir DIR;

  $c->res->headers->cache_control('max-age=1, no-cache');
  $c->render(
    json => {
      hello => $name, 
      MojoHome => $home,
      File => @files 
      }
  );
}

1;
