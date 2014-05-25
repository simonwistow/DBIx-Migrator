package DBIx::Migrator::Strategy::Hash;

use strict;
use base qw(DBIx::Migrator::Strategy);
use Digest::MD5 qw(md5_hex);
use DBIx::DBSchema;
use Data::Dumper;

sub new {
  my $class = shift;
  my %opts  = @_;
  return bless \%opts, $class;
}

sub up {
  my $self   = shift;
  my $i      = 0;
  my $runs   = $self->{runs};
  my $dbh    = $self->{dbh};

  my ($tables, $values) = $self->_get_states;

  $dbh->begin_work or die $dbh->errstr;
  while (1) {
    my $ran = 0;
    last if $runs && $i++ == $runs;
    foreach my $table (sort keys %$tables) {
      $ran += $self->_handle_table($table, $tables->{$table});
      $ran += $self->_handle_table_values($table, $values->{$table});
    }
    last unless $ran;
  }
  $dbh->commit or die $dbh->errstr;
}

sub down {
  die "Can't do 'down' using the Hash strategy";
}

sub _handle_table {
  my $self   = shift;
  my $table  = shift;
  my $states = shift;
  my $hash   = $self->_get_table_hash($table);

  unless ($hash) {
    $self->warn("Table '$table' doesn't exist");
    $hash = '';
  }

  if (defined $states->{$hash}) {
    $self->warn("Table '$table' is out of date");

    eval { $states->{$hash}->up };
    if ($@) {
      $self->error("Table migration $hash on '$table' failed: $@");
      return 0;
    }
    return 1;
  } elsif (exists $states->{$hash}) {
    $self->ok("Table '$table' is up to date ($hash)");
  } else {
    $self->error("Table '$table' is in an unknown state ($hash)");
  }

  return 0;
}

sub _handle_table_values {
  my $self   = shift;
  my $table  = shift;
  my $states = shift;
  my $hash   = $self->_get_value_hash($table);

  if (defined $states->{$hash}) {
    $self->warn(">> Fields for table '$table' do not match $hash");

    eval { $states->{$hash}->up };
    if ($@) {
      $self->error("Value migration $hash on '$table' failed: $@");
      return 0;
    }
    return 1;
  } elsif (exists $states->{$hash}) {
    $self->ok(">> Table '$table' fields match");
  } else {
    $self->error(">> Table '$table' fields are in inconsistent state $hash");
  }

  return 0;
}

sub _get_table_hash {
  my $self  = shift;
  my $table = shift;

  my $schema = DBIx::DBSchema->new_native($self->{dbh});
  my $spec  = eval { $schema->table($table)->sql_create_table($self->{dbh}) };
  # TODO: It would be nice to be able to force a common format on the SQL
  # (by passing e.g "dbi:mysql:database" instead of $self->{dbh}) to sql_create_table
  # because then, theoretically, migrations would stay portable across databases.
  # However DBIx::DBSchema is kind of buggy
  return $spec ? md5_hex($spec) : undef;
}

sub _get_value_hash {
  my $self  = shift;
  my $table = shift;
  # TODO: no ordering  - maybe inspect using DBIx::DBSchema to order by primary key
  # or does that happen automatically on all databases?
  my $rows  = $self->{dbh}->selectall_arrayref("SELECT * FROM $table");
  # TODO: is Dumper output stable? It seems to be between runs but between releases?
  return @$rows ? md5_hex(Dumper($rows)) : "";
}

sub _get_states {
  my $self   = shift;
  my $tables = {};
  my $values = {};
  foreach my $m ($self->migrations) {
    my $table     = $m->table || next;
    $tables->{$table}->{$_} = $m    for $m->table_before;
    $tables->{$table}->{$_} = undef for $m->table_after;
    $values->{$table}->{$_} = $m    for $m->values_before;
    $values->{$table}->{$_} = undef for $m->values_after;
  }
  return ($tables, $values);
}

package DBIx::Migrator::Migration::Hash;
use strict;
use base qw(DBIx::Migrator::Migration);

sub table_before {}
sub table_after {}
sub values_before { }
sub values_after {}

1;
