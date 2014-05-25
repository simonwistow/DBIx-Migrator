package Hash2;
use strict;
use base qw(DBIx::Migrator::Migration::Hash);

sub table { "hashtest" }
sub values_before { "" }
sub values_after  { "cee8ec92cefddd6822ff54a562ebe6b5" }

sub up {
    my $self = shift;
    $self->{dbh}->do("INSERT INTO hashtest ('testing') VALUES (8)");
}

sub down {
    my $self = shift;
    $self->{dbh}->do("DROP TABLE hashtest");
}
1;