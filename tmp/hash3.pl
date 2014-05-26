package Hash3;
use strict;
use base qw(DBIx::Migrator::Migration::Hash);

sub table { "hashtest" }
sub table_before { "c4ca4238a0b923820dcc509a6f75849b" }
sub table_after  { }

sub up {
    my $self = shift;
    warn "Adding column\n";
    $self->{dbh}->do("ALTER TABLE hashtest ADD foobar STRING");
    warn "Done column\n";
}

sub down {
    my $self = shift;
    $self->{dbh}->do("ALTER TABLE hashtest DROP COLUMN foobar");
}
1;