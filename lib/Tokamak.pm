use strict;
use warnings;
package Tokamak;

use App::Cmd::Setup -app;

use lib "$ENV{'HOME'}/.tokamak/lib";

#sub plugin_search_path { my ($self) = @_; my $path = $self->SUPER::plugin_search_path; push @$path, "Tokamak::Extra"; return $path }

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

#print STDERR "% " . $ENV{SDC_ACCOUNT} . " @ " . $ENV{SDC_URL} . "\n";
#print STDERR "\n";

sub plugin_search_path {
  my ($self) = @_;

  return [ 'Tokamak::Command', 'Tokamak::Extra' ];
}

1;
