package Foo;
use strict;
use base qw(DBIx::Migrator::Migration::Serial);

sub up {
    my $self = shift;
    $self->{dbh}->do("CREATE TABLE IF NOT EXISTS foo (test INT NOT NULL)");
}

sub down {
    my $self = shift;
    $self->{dbh}->do("DELETE TABLE foo");
}
1;