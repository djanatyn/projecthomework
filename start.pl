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

  my @todo;
  my @done;

  open(TASKS,"$user/tasks");
  for my $task (<TASKS>) {
    if ($task =~ /^todo: (.+)/) {
      push @todo, $1;
    };
    if ($task =~ /^done: (.+)/) {
      push @done, $1;
    };
  };

  $user =~ s/users\///;

  $users{$user}->{pass} = $pass;

  $users{$user}->{done} = \@done;
  $users{$user}->{todo} = \@todo;
};

sub getMessage {
  my $msg = session('message');
  session 'message' => '';
  return $msg; };

sub setMessage {
  session 'message' => shift; };

any ['get', 'post'] => '/' => sub {
  template 'index.tt', {
    'message' => getMessage(),
    todo => $users{params->{name}}->{todo},
    done => $users{params->{name}}->{done},
  };
};

post '/login' => sub {
  if (exists $users{param('user')}) {
    if (param('pass') eq $users{param('user')}->{pass}) {
      session 'username' => param('user');
      setMessage("logged in successfully");
    } else {
      setMessage("bad password");
    };
  } else {
    mkdir './users/' . param('user');
    write_file('./users/'. param('user') . '/pass',param('pass'));

    $users{param('user')}->{pass} = param('pass');

    setMessage('created new account "' . param('user') . '".');
  };
  redirect '/';
};

get '/logout' => sub {
  session->destroy;
  setMessage("logged out successfully");
  redirect '/';
};

get '/users/:name' => sub {
  if (exists $users{params->{name}}->{pass}) {
    template 'user.tt', {
      user => params->{name},
      todo => $users{params->{name}}->{todo},
      done => $users{params->{name}}->{done},
    };
  } else {
    setMessage("no such user");
    redirect '/';
  };
};

dance;
