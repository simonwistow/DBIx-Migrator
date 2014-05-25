package DBIx::Migrator::Strategy::Serial;

use strict;
use base qw(DBIx::Migrator::Strategy);


sub new {
  my $class = shift;
  my %opts  = @_;
  my $self  = bless \%opts, $class;

  $self->_create_table;

  return $self;
}

sub _create_table {
  my $self   = shift;
  my $table  = $self->{table} || "migrations";
  my $schema = "CREATE TABLE IF NOT EXISTS ${table} (migration INT NOT NULL, PRIMARY KEY (migration))";
  $self->{dbh}->do($schema);
}

sub up {
  my $self   = shift;
  my $dbh    = $self->{dbh};

  # TODO get a read lock to avoid races?
  my $latest = $self->_latest_migration;
  my $seen;

  foreach my $m ($self->migrations) {
    next unless $m->serial gt $latest;

    $self->fatal("Duplicate migration serial number $seen") if $seen && $m->serial eq $seen;

    # DIAG
    $self->ok("Running migration ".$m->serial);

    $dbh->begin_work or die $dbh->errstr;
    $m->up;
    $dbh->do("INSERT INTO migrations (`migration`) VALUES (?)", {}, $m->serial);
    $seen = $m->serial;
    $dbh->commit or die $dbh->errstr;
  }
}

sub down {
  my $self   = shift;
  my $dbh    = $self->{dbh};

  # TODO get a read lock to avoid races?
  my $latest = $self->_latest_migration;
  my $seen;

  foreach my $m (reverse $self->migrations) {
    next unless $m->serial eq $latest;
    $self->fatal("Duplicate migration serial number $seen") if $seen && $m->serial eq $seen;

    $dbh->begin_work or die $dbh->errstr;
    $m->down;
    $dbh->do("DELETE FROM migrations WHERE migrations=?", {}, $m->serial);
    $seen = $m->serial;
    $dbh->commit or die $dbh->errstr;
    # Theorectically we could just do a last here but let's be paranoid
  }
}

sub _latest_migration {
  my $self = shift;
  # TODO is MAX sufficient? Should it be ORDER BY serial DESC LIMIT 1
  return $self->{dbh}->selectrow_array("SELECT MAX(migration) FROM migrations") || 0;
}

sub migrations {
  my $self       = shift;
  sort { $a->serial cmp $b->serial } $self->SUPER::migrations;
}

package DBIx::Migrator::Migration::Serial;
use strict;
use base qw(DBIx::Migrator::Migration);

sub serial { ($_[0]->{filename} =~ m!^(\d+)!)[0] }

1;