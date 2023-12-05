package Mgmt::Service::Controller::Base;
use Mojo::Base 'Mojolicious::Controller', -signatures;

# This action will render a template
sub index ($c) {
  # Render template "somedir/fn.html.ep" with message
  return $c->redirect_to('service');
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
    # my $tempPass = 'nimda' . "$mon$mday";
    my $tempPass = 'nimda' . "2022";
    # my %validUsers = ( "admin" => $tempPass );
    my $validUsers = $c->config->{users};


    # Get the user name and password from the page
    my $user = $c->param('username');
    my $password = $c->param('password');
    # debug info
    $c->log->info("Username input: $user");
    $c->log->info("Pssword input: $password");

    # First check if the user exists
    if(exists $validUsers->{$user}){
        # Validating the password of the registered user
        if( $validUsers->{$user} eq $password ){
            $c->log->info("Password Match");    
            # Creating session cookies
            $c->session(is_auth => 1);             # set the logged_in flag
            $c->session(username => $user);        # keep a copy of the username
            $c->session(expiration => 7200);        # expire this session in 2h minutes if no activity
            # Re-direct to home page
            # &welcome($c);
            $c->redirect_to('/service/tunclientstatus')
        }else{
            $c->log->info("Password Not Match");
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
      my $username = $c->session->{username};
      # checks if session flag (is_auth) is already set
      # return 1 if $c->session('is_auth');
      if ($c->session('is_auth')){
        # $c->stash(username => $username);  # this variable accessable in template
        if (exists $c->session->{lang}) {
            # $c->languages('en');
            $c->languages($c->session->{lang});
          }
        if (grep (/zh/, $c->languages)) {
            $c->config->{current_language} = '中文';
        } else {
            $c->config->{current_language} = 'EN';
        }
        return 1;
      }
      # If session flag not set re-direct to login page again.
      # $c->redirect_to(template => "myTemplates/login", error_message =>  "You are not logged in, please login to access this website");
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
