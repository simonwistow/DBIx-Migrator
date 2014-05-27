#!perl -w

use lib qw(lib);
use DBIx::Migrator;
use DBI;
use Data::Dumper;

my $filename = "test.db";
my $dbh = DBI->connect("dbi:SQLite:dbname=$filename","","", { RaiseError => 1 });
#my $dbh = DBI->connect("dbi:mysql:dbname=heavenly;host=mysql","root",undef, { RaiseError => 1 }) or die $DBI::errstr;
#my $dbh = DBI->connect("dbi:Pg:dbname=simontest;host=mysql",'simon','password', { RaiseError => 1 }) or die $DBI::errstr;

my $strategy = shift || "serial";

my $m = DBIx::Migrator->new(
    strategy  => $strategy,
    dbh       => $dbh,
    directory => 'tmp',
);

$m->up;
