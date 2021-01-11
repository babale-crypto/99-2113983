#!/usr/bin/env perl
## ################################################
## This code is not tested and it's for the purpose of demonstration only.
## It may or may not work.
## ################################################
use strict;
use warnings;
use JSON;
use LWP::UserAgent;
use HTTP::Request::Common qw(GET);

my $meta_top_url = "http://169.254.169.254/latest/meta-data/";
my $item_uri;

if (@ARGV) {
  $item_uri = shift;

  # basic sanity checks (expect alphanum, dash and slash as optional
  die "Parameter contains invalid character!\n" unless ($item_uri =~ /^[a-z0-9\/?-]+$/i);
}

# ensure uri ends with only one slash
$meta_top_url .= "/";
$meta_top_url =~ s/\/{2,}$/\//;
# Force lowercase uri
$meta_top_url = lc $meta_top_url;

my %data_hash;

if ($item_uri){
  $item_uri = lc $meta_top_url . $item_uri;
  $v = get_instance_meta($item_uri);
  $data_hash[$y] = $v;
}
else {
  # Need top-level meta data (get list of items)
  my @x = get_instance_meta($meta_top_url);

  if (@x){
    # recursively get meta item
    for $y (@x){
      my $this_item = lc $meta_top_url . $y;
      $v = get_instance_meta($this_item);
      $data_hash[$y] = $v;
    }
  }
}

#Output JSON
my $meta_data_json = to_json(%data_hash);
print "$meta_data_json\n"


sub get_instance_meta {
  my $uri = shift;
  my $ua = LWP::UserAgent->new;
  $ua->agent('Mozilla/8.0');
  my $req = HTTP::Request->new(GET => $uri);
  $req->header("content-type" => "text/plain");
  my $res = $ua->request($req);

  #Set true if successful outcome
  if ($res->is_success) {
      push @retvalues, (1,$res->status_line, $res->decoded_content);
  }
  else{
      push @retvalues, (undef, $res->status_line, $res->decoded_content);
  }
}

