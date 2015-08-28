package Tokamak::Command::destroy;
use Tokamak -command;

use strict;
use warnings;

use JSON;

use Data::Printer;

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

  my $name = qx/carton exec .\/local\/bin\/route53 -keyname default record list helium.team. | grep $ip | awk '{print \$1}'/;
  chomp $name;

  if ( $name ) {
    print "% DNS  Deleting DNS record: $name ($ip)\n";
    my $cmd = qx/carton exec .\/local\/bin\/route53 -keyname default record delete helium.team. --name $name --type A/;
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

  chomp $chef_name;

  if ( $chef_name ) {
    print "% CHEF Deleting $chef_name\n";
    my $cleanup = qx/knife node delete "$chef_name" -y ; knife client delete "$chef_name" -y/;
  }
}

sub destroy_machine {
  my $id = shift;

  print "% SDC  Destroying $id: ";

  my $destroy = `sdc-deletemachine $id 2> /dev/null`;

  my $i = 0;
  while ( $i <=30 ) {
    my $json = JSON->new->utf8->pretty->allow_nonref;

    my $cmd = `sdc-getmachine $id 2> /dev/null`;

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

  my $machine = `sdc-getmachine $id`;
  my $json = JSON->new->utf8->pretty->allow_nonref;
  my $obj  = $json->decode($machine); 

  if ($machine) { 
    remove_route53_record($obj->{primaryIp});
    remove_chef_record($obj->{primaryIp});
    destroy_machine($id);
  } else {
    print "% Machine $id not found.\n";
    exit 1;
  }
}

1;
