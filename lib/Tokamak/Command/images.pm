package Tokamak::Command::images;
use Tokamak -command;

use strict;
use warnings;

use JSON;
use Text::Table;

use Data::Printer;

=head1 NAME

Tokamak::Command::images - list available container images

=cut

sub opt_spec {
  [ "all|a", "show unfiltered list of container images" ]
}

sub validate_args {
  my ($self, $opt, $args) = @_;
}

sub image_whitelist {
  my $image_data = qx/ knife data bag show tokamak images -Fj 2> \/dev\/null /;
  my $json = JSON->new->utf8->pretty->allow_nonref;
  my $images_json = $json->decode( $image_data );
  
  return @{$images_json->{list}};
}

sub sdc_images {
  my @image_whitelist = @_;

  my $image_list = qx/ sdc-listimages /;
  my $json = JSON->new->utf8->pretty->allow_nonref;
  my $sdc_images = $json->decode( $image_list );

  my $i = 0;
  my $images_num = $#{$sdc_images};
  my %images;

  for ( $i .. $images_num ) {
    my $image_id = $sdc_images->[$i]->{id};
    if ( grep /$image_id/, @image_whitelist ) {
      $images{ $image_id }{ name }   = $sdc_images->[$i]->{name};
      $images{ $image_id }{ version} = $sdc_images->[$i]->{version};
      $images{ $image_id }{ os }     = $sdc_images->[$i]->{os};

      if ( $sdc_images->[$i]->{tags}->{role} ) {
        $images{ $image_id }{ role }   = $sdc_images->[$i]->{tags}->{role};
      }
      else {
        $images{ $image_id }{ role } = "-";
      }

      # Default virtualization type.
      $images{ $image_id }{ type }   = "OS";

      # If OS is "linux", "bsd", etc, we are a KVM image.
      if ( $sdc_images->[$i]->{os} ne "smartos" ) {
        $images{ $image_id }{ type } = "KVM";
      }

      # Unless we have a kernel version tagged, in which case we're an LX branded
      # zone.
      if ( $sdc_images->[$i]->{tags}->{kernel_version} ) {
        $images{ $image_id }{ type } = "LX";
        $images{ $image_id }{ name } = $images{ $image_id }{ name } . "-lx";
      }

    }

    $i++;
  }

  return %images;
}

sub execute {
  my ($self, $opt, $args) = @_;

  my @image_whitelist = image_whitelist();

  my %images = sdc_images(@image_whitelist);

  my $tb   = Text::Table->new( "UUID", "TYPE", "OS", "ROLE", "NAME", "VERSION" );

  foreach my $key ( keys %images ) {
    $tb->add (
      $key,
      $images{$key}->{type},
      $images{$key}->{os},
      $images{$key}->{role},
      $images{$key}->{name},
      $images{$key}->{version},
    );
  }

  print $tb;
}

1;
