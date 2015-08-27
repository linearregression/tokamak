package Tokamak::Command::roles;
use Tokamak -command;

use strict;
use warnings;

use JSON;
use Text::Table;

=head1 NAME

Tokamak::Command::roles - list roles defined in Chef

=cut

my %roles;

sub opt_spec {
}

sub validate_args {
  my ($self, $opt, $args) = @_;
}

sub get_roles {
  my ($self, $opt, $args) = @_;

  my $cmd  = qx/ knife search role -F json '*:*' /;
  my $json = JSON->new->utf8->pretty->allow_nonref;
  my $res  = $json->decode( $cmd );

  my $i = 0;
  my $num = $res->{results};

  for ( $i .. $num ) {
    next unless $res->{rows}[$i]->{name};

    my $name = $res->{rows}[$i]->{name};

    if ( $res->{rows}[$i]->{description} ) {
      $roles{$name}{description} = $res->{rows}[$i]->{description};
    } else {
      $roles{$name}{description} = "-";
    }

    $i++;
  }
}

sub execute {
  my ($self, $opt, $args) = @_;

  get_roles();

  my $tb = Text::Table->new( "ROLE", "DESCRIPTION" );

  foreach my $key ( keys %roles ) {
    $tb->add (
      $key,
      $roles{$key}->{description},
    );
  }

  print $tb;

}

1;
