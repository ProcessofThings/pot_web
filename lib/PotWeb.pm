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
   my $hex;
	
	$self->app->secrets(["adfhh920hlaksdhf02hlkdfhaasdfhg92hfajksdhfkjgdskjfaksdfasdf"]);
	my $sessions = Mojolicious::Sessions->new;
	$self->sessions->cookie_name('pot_web');
  $self->sessions->default_expiration('3600');
  $self->sessions->cookie_name('session');

  # Load configuration from hash returned by "my_app.conf"
  my $config = $self->plugin('Config');

  # Documentation browser under "/perldoc"
  $self->plugin('ACME');
  $self->plugin('PODRenderer') if $config->{perldoc};
  $self->plugin('DebugDumperHelper');
  $self->plugin('PotWeb::Helpers');
  $self->plugin('PotWeb::Proxy');

   # Router
  my $r = $self->routes;

  # Normal route to controller

  $r->get('/node/join')->to('node#join')->name('node');
  $r->get('/node/alive')->to('node#alive')->name('node');
  $r->get('/redirect')->to('system#redirect');
  $r->any('/api/*myfunc')->to('system#api');
  $r->get('/public/*file')->to('system#main');
  $r->get('/ipfs/:id/*file')->to('system#ipfs');
  $r->get('/')->to('system#main');
  $r->get('/*file')->to('system#main');

}

1;
