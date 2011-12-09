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
session 'previous' => '/';

my %users;
sub reload {
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
};

reload;

# sub toggle {
#   my ($task, $executor) = shift;
#   open(TASKS,"users/$executor/tasks");
#   my @buffer;
#   for (<TASKS>) {
#     if (/$task/) {
#       if (/^todo: /) { push @buffer, "done: $task"; };
#       if (/^done: /) { push @buffer, "todo: $task"; }
#     } else {
#       push @buffer, $_;
#     }
#   }
#   close(TASKS); open(TASKS,">users/executor/tasks");
#   for (@buffer) {
#     print TASKS $_;
#   }

#   close(TASKS);
# };

sub purge {
  my $executor = shift;
  open(TASKS,"users/$executor/tasks");

  my @buffer;

  for (<TASKS>) {
    if (/^todo: /) {
      push @buffer, $_;
    };
  };

  close(TASKS);

  open(TASKS,">users/$executor/tasks");
  for my $line (@buffer) {
    print TASKS $line;
  };
};

sub getMessage {
  my $msg = session('message');
  session 'message' => '';
  return $msg; };

sub setMessage {
  session 'message' => shift; };

get '/' => sub {
  session 'previous' => '/';
  template 'index.tt', {
    'message' => getMessage(),
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
  redirect session('previous');
};

get '/purge' => sub {
  purge(session('username'));
  setMessage("purged tasks");
  redirect session('previous');
};

post '/add' => sub {
  write_file('./users/' . session('username') . '/tasks', {append => 1}, "\ntodo: " . param('task'));
  setMessage('added task "' . param('task') . '".');
  reload;
  redirect session('previous');
};

get '/logout' => sub {
  session->destroy;
  setMessage("logged out successfully");
  redirect session('previous');
};

get '/users/:name' => sub {
  if (exists $users{params->{name}}) {
    session 'previous' => '/users/' . params->{name};
    template 'user.tt', {
      user => params->{name},
      message => getMessage(),
      todo => $users{params->{name}}->{todo},
      done => $users{params->{name}}->{done},
    };
  } else {
    setMessage("no such user");
    redirect session('previous');
  };
};

# get '/toggle/:task' => sub {
#   toggle(params->{task},session('username'));
#   reload;
#   setMessage('task "' . param('task') . '" toggled.');
#   redirect session('previous');
# };

dance;
