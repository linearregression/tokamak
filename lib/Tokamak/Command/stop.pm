package Tokamak::Command::stop;
use Tokamak -command;

use strict;
use warnings;

use JSON;

use Data::Printer;

=head1 NAME

Tokamak::Command::stop - stop a container

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
  print "Stopping $id: ";

  my $halt = `sdc-stopmachine $id 2> /dev/null`;

  my $i = 0;
  while ( $i <=30 ) {
    my $json = JSON->new->utf8->pretty->allow_nonref;

    my $cmd = `sdc-getmachine $id`;

    my $obj = $json->decode($cmd);

    if ( $obj->{state} ne "stopped" ) {
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
