#!/usr/bin/env perl
# ################################################
# This code is not tested and it's for the purpose of demonstration only.
# It may or may not work.
# ################################################

use strict;
use warnings;
use JSON;
#use Data::Dumper;

my $json = '{"x":{"y":{"z":"a"}}}';

# Call function by named paramters
my $value = get_json_value({json => "$json", key => "x/y/z"});


sub get_json_value {
  my ($args) = @_;
  my $json = $args->{json} if $args->{json};
  my $key   = $args->{key} if $args->{key};

  die "Expect object and key\n" unless $json && $key;

  my @x = split('/',$key);
  my $perldata = decode_json($json);
  print $perldata->{$x[0]}->{$x[1]}->{$x[2]} . "\n";
}
