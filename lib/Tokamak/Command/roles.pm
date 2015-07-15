package Tokamak::Command::roles;
use Tokamak -command;

use strict;
use warnings;

use JSON;
use Text::Table;

=head1 NAME

Tokamak::Command::roles - list roles defined in Chef

=cut

sub opt_spec {
}

sub validate_args {
  my ($self, $opt, $args) = @_;
}

sub execute {
  my ($self, $opt, $args) = @_;

  my $chef_search = qx/ knife role list /;
  print $chef_search;
}

1;
