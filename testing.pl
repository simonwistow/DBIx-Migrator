#!perl -w

use lib qw(lib);
use DBIx::Migrator;
use DBI;
use Data::Dumper;

my $filename = "test.db";
my $dbh = DBI->connect("dbi:SQLite:dbname=$filename","","", { RaiseError => 1 });
#my $dbh = DBI->connect("dbi:mysql:dbname=heavenly;host=mysql","root",undef, { RaiseError => 1 }) or die $DBI::errstr;

my $strategy = shift || "serial";

my $m = DBIx::Migrator->new(
    strategy  => $strategy,
    dbh       => $dbh,
    directory => 'tmp',
);

$m->up;

# my $db_catalog = '';
# my $db_schema  = '%';
# my $sth = $dbh->table_info($db_catalog, $db_schema,  '%', 'TABLE') or die $dbh->errstr;
# die Dumper $sth->fetchall_arrayref([2,3])