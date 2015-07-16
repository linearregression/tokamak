package Tokamak::Command::create;

use strict;
use warnings;

use Tokamak -command;
use Tokamak::Config;
use Tokamak::Constants;

use Carp;
use JSON;
use Data::Printer;

=head1 NAME

Tokamak::Command::create - create a container

=cut

sub opt_spec {
  [ "alias|a=s", "alias [required]",
    { required => 1  } ],

  [ "type|t=s",  "virtualization type (os, lx, kvm) [required]",
    { required => 1 } ],

  [ "size|s=s",    "size alias or UUID" ],
  [ "image|i=s",   "image alias or UUID" ],
}

sub validate_args {
  my ($self, $opt, $args) = @_;

  # Set opt to defaults unless opt is set.

  my $valid_type = Tokamak::Constants::valid_type( $opt->{type} );
  unless ( $valid_type ) { croak "ERROR: " . $opt->{type} ." is not a valid virtualization type\n" }

  if ( $opt->{size} ) {
    $opt->{size_uuid} = Tokamak::Command::sizes::get_uuid_from_name( $opt->{type}, $opt->{size} );
  }
  else {
    $opt->{size_uuid} = Tokamak::Command::sizes::default_size( $opt->{type} );
  }

  if ( $opt->{image}) {
    $opt->{image_uuid} = Tokamak::Command::images::get_uuid_from_name( $opt->{type} );
  }
  else {
    $opt->{image_uuid} = Tokamak::Command::images::default_image( $opt->{type} );
  }

  $opt->{network_uuid} = Tokamak::Command::networks::default_network();
}

sub execute {
  my ($self, $opt, $args) = @_;

  my $alias           = $opt->{alias};
  my $type            = $opt->{type};
  my $size            = $opt->{size};
  my $size_uuid       = $opt->{size_uuid};
  my $image_uuid      = $opt->{image_uuid};
  my $network_uuid    = $opt->{network_uuid};
  my $owner           = $ENV{SDC_KEY_ID};

  $owner           =~ s/://g;

  my $json = JSON->new->utf8->pretty->allow_nonref;

  my $cmd = qx/ sdc-createmachine --image $image_uuid --network $network_uuid --package $size_uuid --name $alias --tag owner=$owner /;

  my $obj = $json->decode($cmd);

  print "Creating $alias " . $obj->{id} . ": ";

  my $i = 0;
  while ( $i <=90 ) {

    my $cmd = qx/ sdc-getmachine $obj->{id} /;
    my $json = JSON->new->utf8->pretty->allow_nonref;
    my $obj = $json->decode($cmd);

    if ( $obj->{state} ne "running" ) {
      print ".";
    }
    else {
      print "done (" . $i . "s).\n";
      print "\n";

      print "Host: ";
      print $obj->{primaryIp} . ": ";
      print $obj->{id} . "\n";

      last;
    }

    $i++;
    sleep 1;
  }
}

1;
