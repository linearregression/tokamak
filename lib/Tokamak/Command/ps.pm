package Tokamak::Command::ps;
use Tokamak -command;

use strict;
use warnings;

use JSON;
use Text::Table;

use Data::Printer;

=head1 NAME

Tokamak::Command::ps - list containers

=cut

sub opt_spec {
  [ "all|a", "verbose output, show all containers" ]
}

sub validate_args {
  my ($self, $opt, $args) = @_;
}

my %machine_types;
my %images;
my $chef_metadata;
my $sdc_images;

$machine_types{ smartmachine   } = "OS";
$machine_types{ virtualmachine } = "VM";

sub get_image {
  my $image_uuid = shift;

  my $image_text = "-";
  my $images_num = $#{$sdc_images};
  my $i = 0;

  for ( $i .. $images_num ) {
    if ( $sdc_images->[$i]->{id} eq $image_uuid ) {
      $image_text = $sdc_images->[$i]->{name} . ":" . $sdc_images->[$i]->{version};
      return $image_text;
    }

    $i++;
  }

  return $image_text;
}

sub chef_role {
  my $ip = shift;

  my $role     = "-";
  my $chef_env = "-";

  if ( $chef_metadata->{results} ) {
    my $i = 0;
    for ( $i .. $chef_metadata->{results} ) {
      foreach my $key ( keys %{$chef_metadata->{rows}[$i]} ) {
        if ( $chef_metadata->{rows}[$i]->{$key}->{ipaddress} eq $ip ) {
          if ( $chef_metadata->{rows}[$i]->{$key}->{role}[0] ) {
            $role = $chef_metadata->{rows}[$i]->{$key}->{role}[0];

            $role =~ s/role\[//g;
            $role =~ s/\]//g;
          }

          if ( $chef_metadata->{rows}[$i]->{$key}->{chef_environment} ) {
            $chef_env = $chef_metadata->{rows}[$i]->{$key}->{chef_environment};
          }

          return ( $role, $chef_env );
         }

       }
    $i++;
    } 
  }

  return ( $role, $chef_env );
}

sub chef_metadata {
  my $chef_search = qx/ knife search \'ipaddress:*\' -F json -a role -a chef_environment -a ipaddress/;
  my $json = JSON->new->utf8->pretty->allow_nonref;
  $chef_metadata = $json->decode( $chef_search );
}

sub sdc_images {
  my $image_list = qx/ sdc-listimages /;
  my $json = JSON->new->utf8->pretty->allow_nonref;
  $sdc_images = $json->decode( $image_list );
}

sub sdc_machines {
  my $machine_list = qx/ sdc-listmachines /;
  my $json = JSON->new->utf8->pretty->allow_nonref;
  my $out = $json->decode( $machine_list );
  return $out;
}

sub execute {
  my ($self, $opt, $args) = @_;

  my $tb;

  if ( $opt->all ) {
    $tb   = Text::Table->new( "UUID", "TYPE", "RAM", "PACKAGE", "IMAGE", "FW", "STATE", "ALIAS", "IP", "ROLE", "ENVIRONMENT" );
  }
  else {
    $tb   = Text::Table->new( "UUID", "TYPE", "RAM", "IMAGE", "ALIAS", "IP", "ROLE" );
  }

  sdc_images();
  chef_metadata();

  my $machines = sdc_machines();

  foreach my $vm ( @{$machines} ) {
    # Skip containers that aren't running, unless called verbosely.
    if ( $vm->{state} ne "running" and !$opt->all ) { next; }

    my $firewall = "-";

    if ( $vm->{firewall_enabled} ) {
      $firewall = "Y";
    }

    my ( $role, $chef_env ) = chef_role( $vm->{primaryIp} );

    my $image_text = get_image( $vm->{ image } );

    if ( $opt->all ) {
      $tb->add(
        $vm->{id},
        $machine_types{ $vm->{type} },
        $vm->{memory},
        $vm->{package},
        $image_text,
        $firewall,
        $vm->{state},
        $vm->{name},
        $vm->{primaryIp},
        $role,
      );
    }
    else {
      $tb->add(
        $vm->{id},
        $machine_types{ $vm->{type} },
        $vm->{memory},
        $image_text,
        $vm->{name},
        $vm->{primaryIp},
        $role,
      );
    
    }
  }

  print $tb;
}

1;
