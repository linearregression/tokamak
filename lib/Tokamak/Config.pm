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

sub set_sdc_env {
  my $env = shift;
  my $config_hash = load_config();

  if ( $config_hash->{ $env } ) {
    $ENV{SDC_ACCOUNT} = $config_hash->{ $env }->{ SDC_ACCOUNT };
    $ENV{SDC_URL}     = $config_hash->{ $env }->{ SDC_URL };
    $ENV{SDC_KEY_ID}  = $config_hash->{ $env }->{ SDC_KEY_ID };
  } else {
    croak "$env is not a valid environment.";
  }
}

1;
