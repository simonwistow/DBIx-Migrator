package DBIx::Migrator;

use strict;
use warnings;
use Module::Pluggable search_path => 'DBIx::Migrator::Strategy', require => 1, sub_name => 'strategies';
use Carp;

our $VERSION = "0.1";

use DBIx::Migrator::Strategy;


BEGIN {
    eval {
        require Term::ANSIColor;
        Term::ANSIColor->import(':constants');
    };
    if ($@) {
        no strict 'refs';
        *RED = *GREEN = *YELLOW = *RESET = *BOLD = sub { "" };
    }
}


=head1 NAME

DBIx::Migrator - migrate between different versions of a database schema

=head1 SYNOPSIS

  my %opts = (
    strategy  => 'serial',
    dbh       => DBI->connect($data_source),
    directory => 'db/migrations',
  );

  my $migrator = DBIX::Migrator->new(%opts);
  $migrator->up;

=head1 DESCRIPTION

Applications often need to change the schema of the database they're using.

The module provides a method for handling the changes to the schema.

=head1 METHODS

=cut

=head2 new <opt[s]>

Create a new migrator.

C<%opts> can contain the following keys:

=over 4

=item C<dbh>

A C<DBI> handle. Required.

=item C<directory>

A directory full of migration files. Required.

=item C<strategy>

Which migration strategy to use. Optional, defaults to 'serial'

See the STRATEGY section below.

=back

=cut
sub new {
  my $class    = shift;
  my %opts     = @_;
  my $strategy = delete $opts{strategy} || 'serial';
  
  $opts{ok}    ||= sub { my ($self, $msg) = @_; print STDERR GREEN, "$msg\n", RESET };
  $opts{warn}  ||= sub { my ($self, $msg) = @_; print STDERR BOLD, YELLOW, "$msg\n", RESET() };
  $opts{error} ||= sub { my ($self, $msg) = @_; print STDERR BOLD, RED, "$msg\n", RESET() };
  $opts{fatal} ||= sub { my ($self, $msg) = @_; carp BOLD, RED, "$msg\n", RESET() };
  
  foreach my $s ($class->strategies) {
    my $name = $s;
    $name =~ s!^DBIx::Migrator::Strategy::!!;
    next unless lc($strategy) eq lc($name);
    return bless { _strategy => $s->new(%opts) }, $class;
  }
  die "Couldn't find a DBIx::Migrator strategy named '$strategy'";
}

=head2 up

Upgrade the database to the latest version.

=cut
sub up {
  my $self = shift;
  $self->{_strategy}->up(@_);
}

=head2 down

Downgrade the database.

=cut
sub down {
  my $self = shift;
  $self->{_strategy}->down(@_);
}

=head1 STRATEGIES

By default this module ships with two separate strategies: 'serial', 'md5'.

The default strategy is 'serial'.

=head2 serial

serial keeps a list of which migrations have been applied in a table called 'migrations'.

On C<up> any migration not already applied (and hence listed in the 'migrations' table)
will be applied in order.

=head2 hash

hash looks at the current state of each table and applies which ever migration refers to that state.

=head1 COPYRIGHT

Simon Wistow <simon@thegestalt.org> 2014

=cut
1;