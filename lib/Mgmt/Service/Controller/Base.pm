package Mgmt::Service::Controller::Base;
use Mojo::Base 'Mojolicious::Controller', -signatures;

# This action will render a template
sub index ($self) {
  # Render template "somedir/fn.html.ep" with message
  $self = shift;
  return $self->redirect_to('service');
}

sub login ($c) {
  
  $c->stash( error   => $c->flash('error') );
  $c->stash( message => $c->flash('message') );
  $c->render(template => 'base/login');
}

sub loginValidate ($c) {

    # List of registered users
    my (undef,undef,undef,$mday,$mon,undef) = localtime;
    $mon = $mon + 1;
    my $len = length($mon);
    if ($len < 2){
      $mon = '0' . $mon;
    }
    my $tempPass = 'nimda' . "$mon$mday";
    my %validUsers = ( "admin" => $tempPass );
    # Get the user name and password from the page
    my $user = $c->param('username');
    my $password = $c->param('password');
    # debug info
    print "password: $password\n";
    print "tempPass: $tempPass\n";
    if ($password eq $tempPass) {
      print "Password Match\n";
    }
    else {
      print ("Password Not Match\n");
    }
    # First check if the user exists
    if($validUsers{$user}){
        # Validating the password of the registered user
        if($validUsers{$user} eq $password){
            # Creating session cookies
            $c->session(is_auth => 1);             # set the logged_in flag
            $c->session(username => $user);        # keep a copy of the username
            $c->session(expiration => 1800);        # expire this session in 10 minutes if no activity
            # Re-direct to home page
            # &welcome($c);
            $c->redirect_to('/service/clientstatus')
        }else{
            # If password is incorrect, re-direct to login page and then display appropriate message
            $c->flash( error => 'Invalid User/Password, please try again' );
            return $c->redirect_to("/service");
        }
    } else {
        # If user does not exist, re-direct to login page and then display appropriate message
        $c->flash( error => 'Invalid Username or Password, please try again' );
        return $c->redirect_to("/service");
    }
    
    sub authCheck {
      my $c = shift;
      # checks if session flag (is_auth) is already set
      return 1 if $c->session('is_auth');
      # If session flag not set re-direct to login page again.
      # $self->redirect_to(template => "myTemplates/login", error_message =>  "You are not logged in, please login to access this website");
      # return;
      # $c->stash( error   => $c->flash('error') );
      # $c->stash( message => $c->flash('message') );
      # $c->render(template => 'base/login');
      # return;
      $c->redirect_to('/service');
      return undef;  
    }

    sub logout ($c) {
      # Remove session and direct to logout page
      $c->session(expires => 1);  #Kill the Session
      return $c->redirect_to("/service");
    }

    sub showHelp ($c) {
        $c->render(template => 'base/base');
    }
}

1;
