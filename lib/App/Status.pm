package App::Status;
# ABSTRACT: Status Monitor

use MooX qw(
  Options
);

use POE qw(
  Component::Server::HTTPServer
  Component::Server::HTTPServer::Handler
  Component::Server::TCP
  Filter::JSONMaybeXS
  Filter::Line
  Filter::Stackable
  Wheel::FollowTail
);

use Protocol::WebSocket::Handshake::Server;
use Protocol::WebSocket::Frame;
use POE::Component::Server::HTTPServer::Handler;

use Scalar::Util qw( blessed );
use File::ShareDir::ProjectDistDir;
use Path::Tiny;
use JSON::MaybeXS;
use HTTP::Status;
use Data::Dumper;
use HTTP::Message::PSGI;
use File::HomeDir;

use File::Path;

use App::Status::Web;

our $VERSION = '0.000';

option ws_port => (
  is => 'ro',
  format => 'i',
  lazy => 1,
  default => sub { 33334 },
);

option port => (
  is => 'ro',
  format => 'i',
  lazy => 1,
  default => sub { 33333 },
);

option default_admin_password => (
  is => 'ro',
  format => 's',
  lazy => 1,
  default => sub { 'appstatus' },
);

option workdir => (
  is => 'ro',
  format => 's',
  lazy => 1,
  default => sub {
    my $workdir = File::HomeDir->my_home
      ? path(File::HomeDir->my_home,'.app-status')->absolute
      : path('.','.app-status')->absolute;
    path($workdir)->mkpath unless -d $workdir;
    return $workdir;
  },
);

has _ws_conns => (
  is => 'rw',
  lazy => 1,
  default => sub {{}},
);

has ws_server => (
  is => 'ro',
  lazy => 1,
  default => sub {
    my ( $self ) = @_;
    POE::Component::Server::TCP->new(
      Port            => $self->ws_port,
      ClientFilter    => 'POE::Filter::Stream',
      ClientConnected => sub {
        $self->_ws_conns->{$_[SESSION]->ID} = $_[HEAP]{client};
        $_[HEAP]{hs} = Protocol::WebSocket::Handshake::Server->new;
        $_[HEAP]{frame} = Protocol::WebSocket::Frame->new;
      },
      ClientDisconnected => sub {
        delete $self->_ws_conns->{$_[SESSION]->ID};
      },
      ClientInput     => sub {
        my $chunk = $_[ARG0];
        if (!$_[HEAP]{hs}->is_done) {
          $_[HEAP]{hs}->parse($chunk);
          if ($_[HEAP]{hs}->is_done) {
            $_[HEAP]{client}->put($_[HEAP]{hs}->to_string);
          }
          return;
        }
        $_[HEAP]{frame}->append($chunk);
        while (my $message = $_[HEAP]{frame}->next) {
          # do we care about input on websocket?
        }
      },
    );
  },
);

has web_app => (
  is => 'ro',
  lazy => 1,
  default => sub {
    my ( $self ) = @_;
    return App::Status::Web->new( app_status => $self )->to_psgi_app;
  },
);

has web_server => (
  is => 'ro',
  lazy => 1,
  default => sub {
    my ( $self ) = @_;
    my $http_server = POE::Component::Server::HTTPServer->new;
    $http_server->port($self->port);
    $http_server->handlers([
      '/' => sub {
        my $context = shift;
        $context->{response} = res_from_psgi($self->web_app->(req_to_psgi($context->{request})));
        return H_FINAL;
      },
    ]);
    $http_server->create_server();
  },
);

has web_root => (
  is => 'ro',
  lazy => 1,
  default => sub { path(dist_dir('App-Status'),'root') },
);

sub BUILD {
  my ( $self ) = @_;
  print " - Starting websocket server on port ".$self->ws_port."... ";
  $self->ws_server;
  print "done\n";
  print " - Starting web server on port ".$self->port."... ";
  $self->web_server;
  print "done\n";
}

sub run {
  $_[0]->new_with_options unless blessed $_[0];
  POE::Kernel->run;
}

1;