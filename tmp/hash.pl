package Hash;
use strict;
use base qw(DBIx::Migrator::Migration::Hash);

sub table { "hashtest" }
sub table_before { "" }
sub table_after  { "f88f2ea79af8a02d6592e7e0dd04f64a" }

sub up {
    my $self = shift;
    $self->{dbh}->do("CREATE TABLE IF NOT EXISTS hashtest (testing INT NOT NULL)");
}

sub down {
    my $self = shift;
    $self->{dbh}->do("DELETE FROM hashtest WHERE testing=8");
}
1;