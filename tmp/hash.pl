package Hash;
use strict;
use base qw(DBIx::Migrator::Migration::Hash);

sub table { "hashtest" }
sub table_before { "" }
sub table_after  { "c4ca4238a0b923820dcc509a6f75849b" }

sub up {
    my $self = shift;
    $self->{dbh}->do("CREATE TABLE IF NOT EXISTS hashtest (testing INT NOT NULL)");
}

sub down {
    my $self = shift;
    $self->{dbh}->do("DELETE FROM hashtest WHERE testing=8");
}
1;