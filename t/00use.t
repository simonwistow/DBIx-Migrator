#!perl -w

use strict;
use warnings;
use Test::More tests => 3;

use_ok("DBIx::Migrator");
use_ok("DBIx::Migrator::Strategy::Hash");
use_ok("DBIx::Migrator::Strategy::Serial");
