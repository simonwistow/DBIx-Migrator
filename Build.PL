use strict;
use Module::Build;

my $build = Module::Build
  ->new( module_name => "DBIx::Migrator",
         license     => 'perl',
         requires    => {
             'DBI'               => '0',
             'Module::Pluggable' => '0',
             'Module::Metadata'  => '0',
             'File::Spec'        => '0',
             'DBIx::DBSchema'    => '0',
         },
         recommends => {
              'Term::ANSIColor'  => '0',
         },
         configure_requires => {
              'Module::Build'    => '0.38', 
         },
         build_requires => {
             'Test::More'        => '0.62',
         },
         create_makefile_pl      => 'small',
         meta_merge     => {
           resources => {
             repository  => 'https://github.com/simonwistow/DBIx-Migrator',
           }
         },
       );


$build->create_build_script;

