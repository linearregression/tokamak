package Tokamak::Constants;

sub virtualization_types {
  my @types = ( "os", "lx", "kvm" );
  return @types;
}

sub valid_type {
  my $type = shift;

  my @types = virtualization_types();
  if ( grep /$type/, @types ) {
    return 1;
  }

  return 0;
}

1;
