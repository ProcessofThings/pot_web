package PotWeb::Controller::System;
use Mojo::Base 'Mojolicious::Controller';

my $redis = Mojo::Redis2->new;

sub api {
	my $c = shift;
	my $host = $c->req->url->to_abs->host;
	my $method = $c->req->method;
	my $myfunc = $c->param('myfunc');
	$c->debug($c->req);
	my $id;
	if ($redis->exists('url_'.$host)) {
		$id = $redis->get('url_'.$host);
	}
	my (undef,$blockchain) = split /:/, $id;
	my $url = "http://127.0.0.1:9090/v1/api/multichain";
	my $base = $url.'/'.$myfunc.'/'.$blockchain;
#	my $base = 'http://127.0.0.1:9090/testapi';
	$c->debug($base);
	
	$c->proxy_to($base,'with_query_params' => 1, 'method' => $method);
}

sub main {
 my $c = shift;
 my $host = $c->req->url->to_abs->host;
# my $file = $c->req->url->to_abs;
 my $file;
 if (defined($c->param('file'))) {
		$c->debug('file detected');
		$file = $c->req->url->to_abs->path;
 } else {
		$file = "index.html";
 }
 my $id;
 if ($redis->exists('url_'.$host)) {
	$c->debug('Found Host on Redis');
   $id = $redis->get('url_'.$host);
   $c->session->{urlid} = $id;
 } else {
   $id = "QmYEzhKy1ZB3dcZtyKrUnqJyp7ZnQQK8EkofUa8Whu2RdM";
 }
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
 $c->debug($c->session);
 ($id,undef) = split /:/, $c->session->{urlid};
 if (-d "/home/node/dev/$id") {
	print "Main Loading Local\n";
	$file = "/home/node/dev/$id/$file";
	$c->res->content->asset(Mojo::Asset::File->new(path => $file));
  $c->rendered(200);
 } else {
	$c->debug('Loading IPFS');
	my $base = "http://127.0.0.1:8080/ipfs/$id/$file";
	$c->proxy_to($base);
 }

}

sub secure {
 my $c = shift;
 my $host = $c->req->url->to_abs->host;
# my $file = $c->req->url->to_abs;
 my $file;
 if (defined($c->param('file'))) {
		$file = $c->req->url->to_abs->path;
 } else {
		$file = "index.html";
 }
 my $id;
 if ($redis->exists('url_'.$host)) {
   $id = $redis->get('url_'.$host);
 } else {
   $id = $c->ipfshash;
 }
 ($id,undef) = split /:/, $id;
 if (-d "/home/node/dev/$id") {
	print "Loading Local\n";
	$file = "/home/node/dev/$id/$file";
	$c->res->content->asset(Mojo::Asset::File->new(path => $file));
  $c->rendered(200);
 } else {
	my $base = "http://127.0.0.1:8080/ipfs/$id/$file";
	$c->proxy_to($base);
 }

}

sub ipfs {
  my $c = shift;
  my $url = $c->req->url->to_string;
  my $id = $c->param('id');
  my $file = $c->param('file');
  my $method = $c->req->method;
  $c->debug($id);
  $c->debug($file);
  my $base = "http://127.0.0.1:8080/ipfs/$id/$file";
  $c->proxy_to($base, 'method' => $method);
}

1;
