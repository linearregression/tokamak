package Tokamak::Command::destroy;
use Tokamak -command;

use strict;
use warnings;

use Tokamak::Config;
use Tokamak::SDC::Machines;

use Carp;
use JSON;

=head1 NAME

Tokamak::Command::destroy - destroy a container

=cut

sub opt_spec {
  [ "json|j",      "json output" ],
}

sub validate_args {
  my ($self, $opt, $args) = @_;

  if ( ! $args->[0] ) {
    print "Container ID required.\n";
    exit 1;
  }
  
  if ( $args->[1] ) {
    print "Only one machine ID allowed.\n";
    exit 1;
  }
}

sub remove_route53_record {
  my $ip = shift;

  my $config_hash = Tokamak::Config::load_config();
  my $default_env = $config_hash->{ core }->{ default_environment };
  my $domain      = $config_hash->{ $default_env }->{ DOMAIN };

  # If we have route53 configured, clean up.
  if ( $domain ) {
    my $name = qx/carton exec .\/local\/bin\/route53 -keyname default record list $domain. | grep $ip | awk '{print \$1}'/;
    chomp $name;

    if ( $name ) {
      print "% DNS  Deleting DNS record: $name ($ip)\n";
      my $cmd = qx/carton exec .\/local\/bin\/route53 -keyname default record delete $domain. --name $name --type A/;
    }
  }
}

sub remove_chef_record {
  my $ip = shift;

  my $cmd = `knife search node 'ipaddress:$ip' -F json -a name`;
  my $json = JSON->new->utf8->pretty->allow_nonref;
  my $obj  = $json->decode($cmd);

  my $chef_name;
  foreach my $k ( keys %{$obj->{rows}[0]} ) {
    $chef_name = $k;
  }

  if ( $chef_name ) {
    chomp $chef_name;
    print "% CHEF Deleting $chef_name\n";
    my $cleanup = qx/knife node delete "$chef_name" -y ; knife client delete "$chef_name" -y/;
  }
}

sub destroy_machine {
  my $id = shift;

  # $id may be truncated for UX reasons. Get the full UUID.
  my $uuid = Tokamak::SDC::Machines::match_id($id);

  print "% SDC  Destroying $uuid: ";

  my $destroy = `sdc-deletemachine $uuid 2> /dev/null`;

  my $i = 0;
  while ( $i <=30 ) {
    my $json = JSON->new->utf8->pretty->allow_nonref;

    my $cmd = `sdc-getmachine $uuid 2> /dev/null`;

    if ( $? != 768 ) {
      print ".";
    }
    else {
      print "done.\n";
      last;
    }

    sleep 1;
  }
}

sub execute {
  my ($self, $opt, $args) = @_;

  my $id = $args->[0];

  # $id may be truncated for UX reasons. Get the full UUID.
  my $uuid = Tokamak::SDC::Machines::match_id($id);
  my $machine = `sdc-getmachine $uuid`;

  my $json = JSON->new->utf8->pretty->allow_nonref;
  my $obj  = $json->decode($machine); 

  if ($machine) { 
    remove_route53_record($obj->{primaryIp});
    remove_chef_record($obj->{primaryIp});
    destroy_machine($uuid);
  } else {
    print "% Machine $uuid not found.\n";
    exit 1;
  }
}

1;
