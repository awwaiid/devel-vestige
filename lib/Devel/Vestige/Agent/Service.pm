package Devel::Vestige::Agent::Service;

use Moo;
use Method::Signatures;
use JSON qw( encode_json decode_json );

use constant PROTOCOL_VERSION => 10;

has agent_id    => (is => 'rw');
has license_key => (is => 'rw');
has host => (is => 'rw', default => sub { 'collector.newrelic.com' });

sub debug(@) {
  eval "use Data::Printer";
  return if $@;
  my (@things) = @_;
  foreach my $thing (@_) {
    if(ref $thing) {
      Data::Printer::p($thing);
    } else {
      $thing ||= '';
      print STDERR $thing;
    }
    print STDERR "\n";
  }
}

method connect_settings() {
  return {
    pid      => $$,
    host     => `hostname`,
    app_name => ['My Application'], # $self->app_name()

    # Lies! All Lies!
    language      => "ruby",
    agent_version => "3.5.4.33",
  };
}

method connect($settings = {}) {
  $settings = { %{ $self->connect_settings() }, %$settings };
  my $host = $self->get_redirect_host;
  $self->host($host->{return_value});
  my $response = $self->invoke_remote( connect => $settings );
  $self->agent_id($response->{agent_run_id});

  return $response;
}

sub get_redirect_host {
  my ($self) = @_;
  return $self->invoke_remote('get_redirect_host');
}

method invoke_remote($method, $args = {}) {
  my $data = encode_json [$args];
  my $response = $self->send_request(
    data => $data,
    host => 'ryujin',
    uri  => $self->remote_method_uri($method),
  );
  debug raw_response => $response;
  return decode_json $response;
}

sub send_request {
  my ($self, %opts) = @_;
  debug uri => $opts{uri}, content => $opts{data};
  my $ua = LWP::UserAgent->new;

  $ua->add_handler("request_send",  sub { shift->dump; return });
  $ua->add_handler("response_done", sub { shift->dump; return });

  my $response = $ua->post(
    $opts{uri},
    'content-type' => 'application/octet-stream',
    'content-encoding' => 'identity',
    'HOST' => $opts{host},
    Content        => $opts{data}
  );
  debug response => $response;
  return $response->content;
}

sub remote_method_uri {
  my ($self, $method) = @_;
  my $params = {
    run_id => $self->agent_id,
    marshal_format => 'json',
  };
  my $host = $self->host;
  my $uri = "http://$host/agent_listener/"
    . PROTOCOL_VERSION
    . '/'
    . $self->license_key
    . '/'
    . $method;
  debug params => $params;
  $uri .= '?' . join('&', map { defined $params->{$_} ? "$_=$params->{$_}" : () } keys %$params);
  debug uri => $uri;
  return $uri;
}


1;

