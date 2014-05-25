package Bar;
use strict;
use base qw(DBIx::Migrator::Migration::Serial);

sub up {
    my $self = shift;
    $self->{dbh}->do("INSERT INTO foo ('test') VALUES (8)");
}

sub down {
    my $self = shift;
    $self->{dbh}->do("DELETE FROM foo WHERE test=8");
}
1;