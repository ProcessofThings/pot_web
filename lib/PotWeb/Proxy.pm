package PotWeb::Proxy;
 
use base 'Mojolicious::Plugin';
use Mojo::JSON qw(decode_json encode_json);
 
our $VERSION = '0.6';
 
sub register {
  my ($self, $app) = @_;
  
  $app->helper(
    proxy_to => sub {
      my $c    = shift;
      my $url  = Mojo::URL->new(shift);
      my %args = @_;
      my $content_type = {};
      my $method = 'get';
      my $file = '';
      my $requrl;
      my $sessionKey;
      $url->query($c->req->params) if ($args{with_query_params});
      $method = lc($args{method}) if ($args{method});
      $requrl = lc($args{url}) if ($args{url});
      $sessionKey = $args{sessionKey} if ($args{sessionKey});
      if (Mojo::IOLoop->is_running) {
        $c->render_later;
        if (defined($file)) {}
        my $headers;
        $headers->{'Content-Type'} = $c->req->headers->content_type if ($c->req->headers->content_type);
        $headers->{'X-Url'} = $requrl;
        $headers->{'X-Session'} = $sessionKey || '';
        $c->debug("headers");
        $c->debug($headers);
        my $json = {};
        $json = encode_json($c->req->json);
        $c->debug($json);
        $c->ua->max_redirects(3);
        $c->ua->max_response_size(0);
        $c->ua->inactivity_timeout(120);
        $c->ua->$method(
          $url => $headers
          => $json =>
          sub {
            my ($self, $tx) = @_;
            _proxy_tx($c, $tx);
          }
        );
      }
      else {
        my $tx = $c->ua->$method($url);
        _proxy_tx($c, $tx);
      }
    }
  );
}
 
sub _proxy_tx {
  my ($self, $tx) = @_;
  $self->debug($tx->res);
  if (my $res = $tx->success) {
    $self->tx->res($res);
    $self->rendered;
  }
  else {
    my $error = $tx->error;
    my $json = $tx->res->json;
    $self->debug("Error");
    $self->debug($error);
    $self->debug($json);
    $self->tx->res->headers->add('X-Remote-Status',
      $error->{code} . ': ' . $error->{message});
    $self->render(json => $json, status => $error->{code});
  }
}
 
1;
__END__
 

=head1 NAME
 
Mojolicious::Plugin::Proxy - Proxy requests to a backend server
 
=head1 SYNOPSIS
 
   plugin 'proxy';
 
   get '/foo' => sub { shift->proxy_to('http://mojolicio.us/') };
 
=head1 DESCRIPTION
 
Proxy requests to backend URL using L<Mojo::UserAgent>.
 
=head1 HELPERS 
 
=head2 proxy_to $url, [%options]
 
Proxies the current request to $url using the L<Mojo::Client> get method.
supports one parameter:
 
=over 4
 
=item with_query_params
 
If this parameter is set to 1, will get query parameters from the current 
request and proxy them to the backend.
 
=back
 
=head1 COPYRIGHT AND LICENSE
 
Copyright (C) 2008-2010, Marcus Ramberg.
 
This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.
 
=cut
 
 

=head1 SEE ALSO
 
L<Mojolicious>, L<Mojolicious::Lite>
