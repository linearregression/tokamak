use strict;
use warnings;
package Tokamak;

use App::Cmd::Setup -app;

=head1 NAME

Tokamak

=cut

use Carp;
use Tokamak::Config;

my $config_hash = Tokamak::Config::load_config();

my $default_env   = $config_hash->{core}->{default_environment};
$ENV{SDC_ACCOUNT} = $config_hash->{ $default_env }->{ SDC_ACCOUNT };
$ENV{SDC_URL}     = $config_hash->{ $default_env }->{ SDC_URL };
$ENV{SDC_KEY_ID}  = $config_hash->{ $default_env }->{ SDC_KEY_ID };

print "% " . $ENV{SDC_ACCOUNT} . " @ " . $ENV{SDC_URL} . "\n";
print "\n";

sub plugin_search_path {
  my ($self) = @_;

  return [ 'Tokamak::Command' ];
}

1;
