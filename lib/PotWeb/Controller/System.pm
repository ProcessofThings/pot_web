package PotWeb::Controller::System;
use Mojo::Base 'Mojolicious::Controller';
use UUID::Tiny ':std';
use Data::UUID;
use Encode::Base58::GMP;

my $redis = Mojo::Redis2->new;

sub api {
  my $c = shift;
  my $host = $c->req->url->to_abs->host;
  my $method = $c->req->method;
  my $myfunc = $c->param('myfunc');
  my $sessionKey;
  my $url;
  $c->debug($c->req);
  my $id;
  if (($redis->exists('url_' . $host))) {
    $id = $redis->get('url_' . $host);
    $sessionKey = $c->session->{usersession};
    my (undef, $blockchain) = split /:/, $id;
    if ($redis->exists('test_api_' . $host)) {
      $url = "http://127.0.0.1:9090/public";
    } else {
      $url = "http://127.0.0.1:9090/v1/api/multichain";
    }
    my $base = $url . '/' . $myfunc . '/' . $blockchain;
    #	my $base = 'http://127.0.0.1:9090/testapi';
    $c->debug($base);
    $c->proxy_to($base, 'with_query_params' => 1, 'method' => $method, 'url' => $host, 'sessionKey' => $sessionKey);
  } else {
    $c->render(json => {'message' => 'Permissions Denied'}, status => 401);
  }
}

sub redirect {
    my $self = shift;
    my $secure = $self->req->url->to_abs->scheme('https')->port(443);
    $self->debug('Secure Port');
    $self->debug($secure);
    $self->redirect_to('/login.html');
}

sub main {
  my $c = shift;
  my $host = $c->req->url->to_abs->host;
  my $file;
  my $id;

  my $checkid = $c->session->{urlid};
  $c->debug("Main $checkid");
  ## Check if file is defined or used default index.html

  if (defined($c->param('file'))) {
    $c->debug('file detected');
    $file = $c->req->url->to_abs->path;
  } else {
    $file = "index.html";
  }

  ## Check to see if there is a url loaded if not divert to process of things

  if ($redis->exists('url_'.$host)) {
    $c->debug('Found Host on Redis');
    $id = $redis->get('url_'.$host);
    $c->session->{urlid} = $id;
    my ($usersession,undef) = $c->uuid();
    $usersession = Encode::Base58::GMP::md5_base58($usersession);
    if (!defined($c->session->{usersession})) {
      $c->debug("No User Session");
      $c->session->{usersession} = $usersession;
    } else {
      $c->debug("User Detected");
    }
  } else {
    my $ip = $c->tx->{remote_address} || '0.0.0.0';
    my $xforward = $c->req->headers->header('X-Forwarded-For') || '0.0.0.0';
    $c->debug("Host Request $host $ip $xforward");
    exit;
  }

  ## Allow override if url param is passed

  if (defined($c->param('url'))) {
    $c->debug("url");
    $host = $c->param('url');
    if ($redis->exists('url_'.$host)) {
     $id = $redis->get('url_'.$host);
     $c->session->{urlid} = $id;
    } else {
     $id = "QmYEzhKy1ZB3dcZtyKrUnqJyp7ZnQQK8EkofUa8Whu2RdM";
    }
  }

  $c->debug("Secure Check");
  my $securecheck = 'secure_'.$id.'_'.$file;
  #if (($file =~ /\.html/) && ($redis->exists($securecheck))) {
  #  $c->redirect_to('/index.html');
  #} else {
    ($id, undef) = split /:/, $c->session->{urlid};
    if (-d "/home/node/dev/$id") {
      $c->debug('Loading Local');
      $file = "/home/node/dev/$id/$file";
      $c->res->content->asset(Mojo::Asset::File->new(path => $file));
      $c->rendered(200);
    } else {
      $c->debug('Loading IPFS');
      my $base = "http://127.0.0.1:8080/ipfs/$id/$file";
      $c->proxy_to($base);
    }
  #}
}

sub ipfs {
  my $c = shift;
  my $url = $c->req->url->to_string;
  my $id = $c->param('id');
  my $file = $c->param('file');
  my $method = $c->req->method;
  if (defined($c->session->{usersession})) {
    my $base = "http://127.0.0.1:8080/ipfs/$id/$file";
    $c->proxy_to($base, 'method' => $method);
  }
}

1;
