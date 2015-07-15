use strict;
use warnings;
package Tokamak;

use App::Cmd::Setup -app;

=head1 NAME

Tokamak

=cut

use Carp;

my $config_file = $ENV{HOME} . "/.tokamakrc";

use Config::INI::Reader;

unless ( -e $config_file ) {
  croak "FATAL: Could not find ~/.tokamakrc.\n\n"; 
}

my $config_hash = Config::INI::Reader->read_file($ENV{HOME} . '/.tokamakrc');

my $sdc_default   = $config_hash->{core}->{sdc_default};
$ENV{SDC_ACCOUNT} = $config_hash->{ $sdc_default }->{ SDC_ACCOUNT };
$ENV{SDC_URL}     = $config_hash->{ $sdc_default }->{ SDC_URL };
$ENV{SDC_KEY_ID}  = $config_hash->{ $sdc_default }->{ SDC_KEY_ID };

print "SDC:   " . $ENV{SDC_ACCOUNT} . " @ " . $ENV{SDC_URL} . "\n";
print "\n";

sub plugin_search_path {
  my ($self) = @_;

  return [ 'Tokamak::Command' ];
}

1;
