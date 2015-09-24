package Tokamak::Command::sizes;
use Tokamak -command;

use strict;
use warnings;

use Carp;
use JSON;
use Text::Table;

use Data::Printer;

=head1 NAME

Tokamak::Command::sizes - list available container sizes

=cut

sub opt_spec {
  [ "all|a", "show unfiltered list of container sizes" ]
}

sub validate_args {
  my ($self, $opt, $args) = @_;
}

my %packages;

sub sdc_packages {
  my $cmd = qx/ sdc-listpackages /;
  my $json = JSON->new->utf8->pretty->allow_nonref;
  my $pkgs = $json->decode( $cmd );

  my $i = 0;
  my $num = $#{$pkgs};

  for ( $i .. $num ) {
    my $id = $pkgs->[$i]->{id};

    $packages{ $id }{ name } = $pkgs->[$i]->{name};
    $packages{ $id }{ ram  } = $pkgs->[$i]->{memory};
    $packages{ $id }{ cpu  } = $pkgs->[$i]->{vcpus};
    $packages{ $id }{ disk } = $pkgs->[$i]->{disk};

    $i++;
  }
}

sub default_size {
  my $type = shift;

  my %packages = size_aliases();

  return $packages{$type}{default};
}

sub get_uuid_from_name {
  my ( $type, $alias ) = @_;

  my %packages = size_aliases();

  foreach my $key ( keys %packages ) {

    next if $key eq "default_size";
    next if $key eq "kvm";
    next if $key eq "os";
    
    if ( exists $packages{$key}{alias} ) {
      next if $packages{$key}{type} ne $type;

      if ( $alias eq $packages{$key}{alias} ) {
        return $key;
      }

      if ( $alias eq $key ) {
        return $key;
      }
    }
  }

  # No matching alias.
  croak "ERROR: $alias is not a valid package size.\n";
}

sub size_aliases {
  my $cmd = qx/ knife data bag show tokamak sizes -Fj 2> \/dev\/null /;
  my $json = JSON->new->utf8->pretty->allow_nonref;
  my $sizes = $json->decode( $cmd );

  $packages{ default_size } = $sizes->{ default_size };
  
  foreach my $type ( keys %{$sizes->{sizes}} ) {
    foreach my $key ( keys %{$sizes->{sizes}->{$type}} ) {
      $packages{ $sizes->{sizes}->{$type}->{$key} }{ alias } = $key;
      $packages{ $sizes->{sizes}->{$type}->{$key} }{ type }  = $type;

      if ( $packages{ default_size } eq $key ) {
        $packages{ $type }{ default } = $sizes->{sizes}->{$type}->{$key};
      }
    }
  }

  return %packages;
}

sub execute {
  my ($self, $opt, $args) = @_;

  sdc_packages();
  size_aliases();

  my $tb   = Text::Table->new( "UUID", "CPU", "RAM", "TYPE", "NAME", "ALIAS" );

  foreach my $key ( keys %packages ) {
    next if $key eq "default_size";
    if ( $packages{$key}->{alias} ) {
      $tb->add (
        $key,
        $packages{$key}->{cpu},
        $packages{$key}->{ram},
        uc $packages{$key}->{type},
        $packages{$key}->{name},
        $packages{$key}->{alias},
      );
    }
  }

  print $tb;
}

1;
