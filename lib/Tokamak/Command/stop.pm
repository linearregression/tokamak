package Tokamak::Command::stop;
use Tokamak -command;

use strict;
use warnings;

use Tokamak::Config;
use Tokamak::SDC::Machines;

use JSON;
use Carp;


=head1 NAME

Tokamak::Command::stop - stop a container

=cut

sub opt_spec {
}

sub validate_args {
  my ($self, $opt, $args) = @_;
  
  if ( $args->[1] ) {
    croak "Only one machine ID allowed.\n";
  }
}

sub execute {
  my ($self, $opt, $args) = @_;

  my $id = $args->[0];

  # $id may be truncated for UX reasons. Get the full UUID.
  my $uuid = Tokamak::SDC::Machines::match_id($id);

  print "Stopping $uuid: ";

  my $halt = `sdc-stopmachine $uuid 2> /dev/null`;

  my $i = 0;
  while ( $i <=30 ) {
    my $json = JSON->new->utf8->pretty->allow_nonref;

    my $cmd = `sdc-getmachine $uuid`;

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
