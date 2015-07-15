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

sub execute {
  my ($self, $opt, $args) = @_;

  # loop for 30s 

  my $id = $args->[0];
  print "Destroying $id: ";

  # XXX Check if machine exists.

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

1;
