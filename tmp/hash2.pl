package Hash2;
use strict;
use base qw(DBIx::Migrator::Migration::Hash);

sub table { "hashtest" }
sub values_before { "" }
sub values_after  { "2b3317d9930b123b7d297bb8d4027c26" }

sub up {
    my $self = shift;
    $self->{dbh}->do("INSERT INTO hashtest ('testing') VALUES (8)");
}

sub down {
    my $self = shift;
    $self->{dbh}->do("DROP TABLE hashtest");
}
1;