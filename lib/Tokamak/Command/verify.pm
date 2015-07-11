package Tokamak::Command::verify;
use Tokamak -command;

use strict;
use warnings;

use JSON;
use Text::Table;

=head1 NAME

Tokamak::Command::verify - verify your admin config

=cut

sub opt_spec {
}

sub validate_args {
  my ($self, $opt, $args) = @_;
}

sub execute {
  my ($self, $opt, $args) = @_;

  # npm sdc installed?
  # sdc env vars set?
  # can talk to SDC API?

  # chef knife installed? 
  # can talk to chef API?
  print "todo\n";
}

1;
