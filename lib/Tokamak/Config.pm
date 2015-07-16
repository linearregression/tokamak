package Tokamak::Config;

use strict;
use warnings;

use Carp;
use Config::INI::Reader;

my $config_file = $ENV{HOME} . '/.tokamakrc';

sub load_config {
  unless ( -e $config_file ) { croak "FATAL: Could not find ~/.tokamakrc.\n\n"; }
  return Config::INI::Reader->read_file($config_file);
}

1;
