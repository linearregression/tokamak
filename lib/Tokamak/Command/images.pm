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


# XXX
# This might make more sense to store in a Chef databag, so we don't have to
# update tokamak everywhere everytime we update an image.
my @image_whitelist = (
  "b67492c2-055c-11e5-85d8-8b039ac981ec", # base-64-lts    14.4.2
  "39f29a9e-cd82-11e4-bd38-0fed3261fa5f", # elasticsearch  14.4.0
  "5683089c-d18d-11e4-b067-9f59180479b9", # mongodb        14.4.0
  "e312a72c-0a18-11e5-9a87-9ba4a03d4234", # postgresql     15.1.1
  "8777db28-d302-11e4-8cf2-8793bd757e0f", # freebsd10      20150325
  "4cbd2426-dee6-11e4-8ae3-b38f8b943cbe", # vespene        1.0.3
  "82d952c4-1b7b-11e5-a299-bb55cb08eab1", # debian7-lx     20150625
  "d8d81aee-20cf-11e5-8503-2bc101a1d577", # debian7        20150702
);

sub opt_spec {
  [ "all|a", "show unfiltered list of container images" ]
}

sub validate_args {
  my ($self, $opt, $args) = @_;
}

sub sdc_images {
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

  my %images = sdc_images();

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
