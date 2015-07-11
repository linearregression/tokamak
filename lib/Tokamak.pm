use strict;
use warnings;
package Tokamak;

use App::Cmd::Setup -app;

=head1 NAME

Tokamak

=cut

print "SDC:   " . $ENV{SDC_ACCOUNT} . " @ " . $ENV{SDC_URL} . "\n";
print "Chef:  /etc/chef/client.rb\n";
print "\n";

sub plugin_search_path {
  my ($self) = @_;

  return [ 'Tokamak::Command' ];
}

1;
