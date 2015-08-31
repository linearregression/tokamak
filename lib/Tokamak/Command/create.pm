package Tokamak::Command::create;

use strict;
use warnings;

use Tokamak -command;
use Tokamak::Config;
use Tokamak::Constants;

use Carp;
use JSON;
use Data::Printer;
use Capture::Tiny ':all';

=head1 NAME

Tokamak::Command::create - create a container

=cut

sub opt_spec {
  [ "alias|a=s", "alias [required]",
    { required => 1  } ],

  [ "type|t=s",  "virtualization type (os, lx, kvm) [required]",
    { required => 1 } ],

  [ "size|s=s",    "size alias or UUID" ],
  [ "image|i=s",   "image alias or UUID" ],
  [ "role|r=s",    "Chef role (must exist)" ],
  [ "json|j",      "json output" ],
}

sub validate_args {
  my ($self, $opt, $args) = @_;

  # Set opt to defaults unless opt is set.

  my $valid_type = Tokamak::Constants::valid_type( $opt->{type} );
  unless ( $valid_type ) { croak "ERROR: " . $opt->{type} ." is not a valid virtualization type\n" }

  if ( $opt->{size} ) {
    $opt->{size_uuid} = Tokamak::Command::sizes::get_uuid_from_name( $opt->{type}, $opt->{size} );
  }
  else {
    $opt->{size_uuid} = Tokamak::Command::sizes::default_size( $opt->{type} );
  }

  if ( $opt->{image}) {
    $opt->{image_uuid} = Tokamak::Command::images::get_uuid_from_name( $opt->{type} );
  }
  else {
    $opt->{image_uuid} = Tokamak::Command::images::default_image( $opt->{type} );
  }

  $opt->{network_uuid} = Tokamak::Command::networks::default_network();
}

sub chef_bootstrap {
  my ( $uuid, $alias, $ip, $role ) = @_;

  my $config_hash = Tokamak::Config::load_config();
  my $default_env = $config_hash->{ core }->{ default_environment };
  my $chef_env    = $config_hash->{ $default_env }->{ CHEF_ENV };

  my $knife_role = "-r 'role[$role]'";

  my $check_role = Tokamak::Command::roles::role_exists( $role );

  if ( $check_role == 1 ) {
    warn "% CHEF $role does not exist. Bootstrapping with no run_list.\n";
    $knife_role = "";
  }

  print "% CHEF bootstrap: host:$alias ip:$ip\n";
  print "% CHEF bootstrap: role:$role\n";
  print "% CHEF bootstrap: chef_env:$chef_env\n";

  
  my ($merged, $exit) = capture_merged {
    system("knife bootstrap $ip -A -E $chef_env -N $alias -x root -F min $knife_role");
  };

  my $logdir = "$ENV{HOME}/.tokamak/logs/$uuid";
  my $logfile = "$logdir/chef_bootstrap.log";
  my $mkdir = qx/mkdir -p $logdir/;

  open(CHEF_OUT, ">$logfile");
  print CHEF_OUT $merged;
  close(CHEF_OUT); 

  if ( $? == 0 ) {
    print "% CHEF bootstrap: complete. See: $logfile\n";

    set_chef_tag( $alias, "sdc_uuid", $uuid );

    set_sdc_tag( $uuid, "chef_role", $role );
    set_sdc_tag( $uuid, "chef_env",  $chef_env );
  } else {
    print "% CHEF bootstrap: FAILED. See: $logfile\n";
  }
}

# XXX Move this to tags.pm
sub set_sdc_tag {
  my ( $uuid, $key, $value ) = @_;

  print "% SDC  tag $key=$value\n";
  my $machinetag = qx/sdc-addmachinetags --tag "$key=$value" $uuid/;

}

sub set_chef_tag {
  my ( $alias, $key, $value ) = @_;

  print "% CHEF tag $key=$value\n";
  my $cheftag = qx/knife tag create $alias $key=$value 2>&1/;
}

sub execute {
  my ($self, $opt, $args) = @_;

  my $alias           = $opt->{alias};
  my $type            = $opt->{type};
  my $size            = $opt->{size};
  my $size_uuid       = $opt->{size_uuid};
  my $image_uuid      = $opt->{image_uuid};
  my $network_uuid    = $opt->{network_uuid};
  my $owner           = $ENV{SDC_KEY_ID};

  $owner           =~ s/://g;

  my $json = JSON->new->utf8->pretty->allow_nonref;

  my $cmd = qx/ sdc-createmachine --image $image_uuid --network $network_uuid --package $size_uuid --name $alias --tag owner=$owner /;

  my $obj = $json->decode($cmd);

  print "% SDC  creating $alias " . $obj->{id} . ": " unless $opt->{json};
  
  # XXX Move this to waitfor()
  my $i = 0;
  while ( $i <=90 ) {

    my $cmd = qx/ sdc-getmachine $obj->{id} /;
    my $json = JSON->new->utf8->pretty->allow_nonref;
    my $obj = $json->decode($cmd);

    if ( $obj->{state} ne "running" ) {
      unless ( $opt->{json} ) {
        print ".";
      }
    }
    else {
      if ( $opt->{json} ) {
        print "$cmd";
      } else {
        print "done (" . $i . "s).\n";
      }

      # Only bootstrap with Chef if a role is defined by the user.
      if ( $opt->{role} ) {
        # XXX wait_for_ssh()
        sleep 10;
        chef_bootstrap( $obj->{id}, $alias, $obj->{primaryIp}, $opt->{role} );
      }

      unless ( $opt->{json} ) {
        print "\n";
        print "IP:   " . $obj->{primaryIp} . "\n";
        print "UUID: " . $obj->{id} . "\n\n";
      }

      last;
    }

    $i++;
    sleep 1;
  }

}

1;
