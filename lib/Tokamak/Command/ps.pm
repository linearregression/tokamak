package Tokamak::Command::ps;
use Tokamak -command;

use strict;
use warnings;

use JSON;
use Text::Table;

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

$machine_types{ smartmachine   } = "OS";
$machine_types{ virtualmachine } = "VM";

sub chef_role {
   my $ip = shift;

   my $json = JSON->new->utf8->pretty->allow_nonref;

   my $cmd = `knife search 'ipaddress:$ip' -F json -a run_list -a chef_environment -c /etc/chef/client.rb 2> /dev/null`;

   my $chef      = $json->decode( $cmd );

   my $run_list;
   my $chef_env;

   if ( $chef->{results} ) {
     foreach my $key ( keys %{$chef->{rows}[0]} ) {
       $run_list = $chef->{rows}[0]->{$key}->{run_list}[0];

       if ( $run_list ) {
         $run_list =~ s/role\[//g;
         $run_list =~ s/\]//g;
       }
       else { $run_list = "-"; }

       $chef_env = $chef->{rows}[0]->{$key}->{chef_environment};
     }
   }
   else {
     $run_list = "-";
     $chef_env = "-";
   }

   return ( $run_list, $chef_env );
}

sub execute {
  my ($self, $opt, $args) = @_;

  my $json = JSON->new->utf8->pretty->allow_nonref;
  my $tb;

  if ( $opt->all ) {
    $tb   = Text::Table->new( "UUID", "TYPE", "RAM", "PACKAGE", "IMAGE", "FW", "STATE", "ALIAS", "IP", "ROLE", "ENVIRONMENT" );
  }
  else {
    $tb   = Text::Table->new( "UUID", "TYPE", "RAM", "IMAGE", "ALIAS", "IP", "ROLE" );
  }

  my $machine_list = qx/ sdc-listmachines /;

  my $out = $json->decode( $machine_list );

  foreach my $vm ( @{$out} ) {

    # Skip containers that aren't running, unless called verbosely.
    if ( $vm->{state} ne "running" and !$opt->all ) { next; }

    my $firewall = "-";

    if ( $vm->{firewall_enabled} ) {
      $firewall = "Y";
    }

    my ( $run_list, $chef_env ) = chef_role( $vm->{primaryIp} );

    my $image_uuid = $vm->{image};

    my $image_json = JSON->new->utf8->pretty->allow_nonref;
    my $image_cmd  = `sdc-getimage $image_uuid 2> /dev/null`; 

    my $image_text;

    if ( $? == 0 ) {
      my $image   = $image_json->decode( $image_cmd );
      $image_text = $image->{name} . ":" . $image->{version};
    }
    else {
      $image_text = "-";
    } 

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
        $run_list,
        $chef_env,
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
        $run_list,
      );
    
    }
  }

  print $tb;
}

1;
