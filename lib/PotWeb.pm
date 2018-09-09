package PotWeb;
use Mojo::Base 'Mojolicious';
use Mojo::Redis2;
use Mojo::ACME;
use Compress::Zlib;
use Data::Dumper;
use PotWeb::Proxy;



# This method will run once at server start
sub startup {
  my $self = shift;
  my $redis = Mojo::Redis2->new;
	my $ipfshash = "QmYEzhKy1ZB3dcZtyKrUnqJyp7ZnQQK8EkofUa8Whu2RdM";

  # Load configuration from hash returned by "my_app.conf"
  my $config = $self->plugin('Config');

  # Documentation browser under "/perldoc"
  $self->plugin('PODRenderer') if $config->{perldoc};
  $self->plugin('DebugDumperHelper');
  $self->plugin('PotWeb::Proxy');

  # Router
  my $r = $self->routes;

  # Normal route to controller
  $r->any('/api/*myfunc')->to('system#api');
  $r->get('/public/*file')->to('system#main');
  $r->get('/ipfs/:id/*file')->to('system#ipfs');
  $r->any('/secure/*file')->to('system#secure');
  $r->get('/')->to('system#main');
  $r->get('/*file')->to('system#main');
}

1;
