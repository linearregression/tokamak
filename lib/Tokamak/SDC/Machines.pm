package Tokamak::SDC::Machines;

use strict;
use warnings;

use JSON;
use Carp;

# Return a hashed JSON document of all machine metadata for the current SDC account. No filtering.
sub list {
  my $machine_list = qx/ sdc-listmachines /;
  my $json = JSON->new->utf8->pretty->allow_nonref;
  my $out = $json->decode( $machine_list );
  return $out;
}

# Return an array of machine IDs for the current SDC account. No filtering.
sub list_ids {
  my $machine_list = qx/ sdc-listmachines /;
  my $json = JSON->new->utf8->pretty->allow_nonref;
  my $out = $json->decode( $machine_list );

  my @machine_ids;

  foreach my $vm ( @{$out}) {
    push @machine_ids, $vm->{id};
  }

  return @machine_ids;
}

# Matches a given ID (which may be truncated for UX reasons) against a list of
# machines from the current SDC account.
# Carps if matches multiple IDs. (This should be very unlikely.)
# Returns the full UUID.
sub match_id {
  my $id = shift;

  my @hosts = list_ids();
  my @matches = grep(/^$id/, @hosts);

  if ( $matches[1] ) {
    my $machines = join(', ', @matches);
    croak "$id matched multiple machines. This should never happen.\nMatches: $machines\n";
  }

  return $matches[0];
}

1;
