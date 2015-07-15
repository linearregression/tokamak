package Tokamak::Command::sizes;
use Tokamak -command;

use strict;
use warnings;

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

sub size_aliases {
  my $cmd = qx/ knife data bag show tokamak sizes -Fj 2> \/dev\/null /;
  my $json = JSON->new->utf8->pretty->allow_nonref;
  my $sizes = $json->decode( $cmd );

  sdc_packages();
  
  foreach my $type ( keys %{$sizes->{sizes}} ) {
    foreach my $key ( keys %{$sizes->{sizes}->{$type}} ) {
      $packages{ $sizes->{sizes}->{$type}->{$key} }{ alias } = $key;
      $packages{ $sizes->{sizes}->{$type}->{$key} }{ type }  = $type;
    }
  }
}

sub execute {
  my ($self, $opt, $args) = @_;

  size_aliases();

  my $tb   = Text::Table->new( "UUID", "CPU", "RAM", "TYPE", "NAME", "ALIAS" );

  foreach my $key ( keys %packages ) {
    if ( $packages{$key}{alias} ) {
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
