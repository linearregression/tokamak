package Tokamak::Command::start;
use Tokamak -command;

use strict;
use warnings;

use JSON;

use Data::Printer;

=head1 NAME

Tokamak::Command::start - start a container

=cut

sub opt_spec {
}

sub validate_args {
  my ($self, $opt, $args) = @_;
  
  if ( $args->[1] ) {
    print "Only one machine ID allowed.\n";
    exit 1;
  }
}

sub execute {
  my ($self, $opt, $args) = @_;

  # loop for 30s 

  my $id = $args->[0];
  print "Starting $id: ";

  my $halt = `sdc-startmachine $id 2> /dev/null`;

  my $i = 0;
  while ( $i <=30 ) {
    my $json = JSON->new->utf8->pretty->allow_nonref;

    my $cmd = `sdc-getmachine $id`;

    my $obj = $json->decode($cmd);

    if ( $obj->{state} ne "running" ) {
      print ".";
    }
    else {
      print $obj->{state} . ".\n";
      last;
    }

    sleep 1;
  }
}

1;
