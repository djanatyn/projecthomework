#!/usr/bin/perl
use warnings;
use strict;

use File::Slurp;
use Dancer;

set 'template'    => 'template_toolkit';
set 'session'     => 'Simple';
set 'logger'      => 'console';
set 'show_errors' => 1;
set 'warnings'    => 1;
set 'access_log'  => 1;

session 'message'  => '';

my %users;
for my $user (<users/*>) {
  my $pass = read_file("$user/pass");
  $user =~ s/users\///;
  $users{$user}->{'pass'} = $pass;
};

sub getMessage {
  my $msg = session('message');
  session 'message' => '';
  return $msg; };

sub setMessage {
  session 'message' => shift; };

get '/' => sub {
  template 'index.tt', {
    'message' => getMessage(),
  };
};

post '/login' => sub {
  if (exists $users{param('user')}) {
    if (param('pass') eq $users{param('user')}->{'pass'}) {
      session 'username' => param('user');
      setMessage("logged in successfully");
    } else {
      setMessage("bad password");
    }
  } else {
    mkdir './users/' . param('user');
    write_file('./users/'. param('user') . '/pass',param('pass'));

    $users{param('user')}->{'password'} = param('pass');

    setMessage('created new account "' . param('user') . '".');
  }
  redirect '/';
};

get '/logout' => sub {
  session->destroy;
  setMessage("logged out successfully");
};

dance;
