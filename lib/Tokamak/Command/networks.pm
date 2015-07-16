package Tokamak::Command::networks;

use strict;
use warnings;

use Tokamak -command;
use Tokamak::Config;

use Carp;
use JSON;
use Text::Table;

use Data::Printer;

=head1 NAME

Tokamak::Command::networks - list available networks

=cut

sub opt_spec {
}

sub validate_args {
  my ($self, $opt, $args) = @_;
}

sub sdc_networks {

  my $cmd = qx/ sdc-listnetworks /;
  my $json = JSON->new->utf8->pretty->allow_nonref;
  my $sdc_networks = $json->decode( $cmd );

  my $i = 0;
  my $networks_num = $#{$sdc_networks};
  my %networks;

  for ( $i .. $networks_num ) {
    my $uuid = $sdc_networks->[$i]->{id};
    $networks{$uuid} = $sdc_networks->[$i]->{name};

    $i++;
  }

  return %networks;
}

sub get_uuid_from_name {
  my $name = shift;

  my %networks = sdc_networks();

  foreach my $key ( keys %networks ) {
    if ( $name eq $networks{$key} ) {
      return $key;
    }

    if ( $name eq $key ) {
      return $key;
    }
  }

  # No matching name.
  croak "ERROR: $name is not a valid network name.\n";

}

sub default_network {

  my $config_hash = Tokamak::Config::load_config();
  my $default_env   = $config_hash->{core}->{default_environment};

  unless ( $config_hash->{ $default_env }->{ SDC_NETWORK } ) {
    croak "ERROR: SDC_NETWORK is not defined in .tokamakrc.\n";
  }

  my $name = $config_hash->{ $default_env }->{ SDC_NETWORK };

  return get_uuid_from_name($name);

  croak "ERROR: No default network found.\n";
}


sub execute {
  my ($self, $opt, $args) = @_;

  my $tb   = Text::Table->new( "UUID", "NAME" );

  my %networks = sdc_networks();

  foreach my $key ( keys %networks ) {
    $tb->add (
      $key,
      $networks{$key},
    );
  }

  print $tb;
}

1;
