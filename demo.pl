#!/usr/bin/env perl

use v5.14;
use lib 'lib';
use YAML::XS qw( LoadFile );
use Devel::Vestige::Agent::Service;
use LWP::Simple;

my $config = LoadFile('newrelic.yml');
use Data::Printer;
p $config;

my $license_key = $config->{common}{license_key};
print "License: $license_key\n";


my $service = Devel::Vestige::Agent::Service->new(
  license_key => $license_key,
);

my $x = $service->connect();
p $x;

# p $service->get_redirect_host;
