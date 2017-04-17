package App::Status::Web;

use Web::Simple;
use Plack::Middleware::Session;
use Plack::Middleware::Static;
use Plack::Session::Store::File;
use File::ShareDir::ProjectDistDir;
use Path::Tiny;
use JSON::MaybeXS;

has app_status => (
  is => 'ro',
  required => 1,
);

has session => (
  is => 'ro',
  lazy => 1,
  builder => 1,
);

sub _build_session {
  my ( $self ) = @_;
  my $session_dir = path($self->app_status->workdir,'.sessions')->absolute;
  $session_dir->mkpath;
  Plack::Middleware::Session->new(
    store => Plack::Session::Store::File->new(
      dir => $session_dir,
    ),
  );
}

has static => (
  is => 'ro',
  lazy => 1,
  builder => 1,
);

sub _build_static {
  my ( $self ) = @_;
  return Plack::Middleware::Static->new(
    path => qr{^/},
    root => $self->app_status->web_root,
  );
}

sub dispatch_request {
  my $self = shift;
  my $env = shift;

  $env->{stash} = {} unless defined $env->{stash};

  "", sub { $self->session },

  # "/overview.json", sub { [ 200, ['Content-Type' => 'text/plain' ], [ encode_json({}) ] ] },

  "/", sub { $env->{PATH_INFO} = '/index.html'; return; },

  "/...", sub { $self->static },

}

1;