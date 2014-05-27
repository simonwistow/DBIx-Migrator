package Hash3;
use strict;
use base qw(DBIx::Migrator::Migration::Hash);

sub table { "hashtest" }
sub table_before { "f88f2ea79af8a02d6592e7e0dd04f64a" }
# sub table_after  { "c6b73a6b67d62241d57aff36623322b9" }

sub up {
    my $self = shift;
    $self->{dbh}->do("ALTER TABLE hashtest ADD foobar STRING");
}

sub down {
    my $self = shift;
    $self->{dbh}->do("ALTER TABLE hashtest DROP COLUMN foobar");
}
1;