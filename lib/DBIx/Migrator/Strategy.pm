package DBIx::Migrator::Strategy;
use strict;
use File::Spec::Functions;
use Module::Metadata;

sub migrations {
    my $self = shift;
    my $dir  = $self->{directory};

    my ($strategy) = (ref($self) =~ m!::([^:]+)$!);

    my %migrations;

    opendir(my $dh, $dir) or die $!;
    while (my $file = readdir($dh)) {
            next if $file =~ /^\./;
            my $path = catfile($dir, $file);
            require($path);
            $migrations{$_} = $file for grep { $_->isa("DBIx::Migrator::Migration::${strategy}") }
                                                Module::Metadata->new_from_file($path)->packages_inside();
    }
    closedir($dh);

    return map { $_->new(dbh => $self->{dbh}, filename => $migrations{$_}) } keys %migrations;
}

sub ok    { $_[0]->{ok}->(@_)    unless $_[0]->{silent} }
sub warn  { $_[0]->{warn}->(@_)  unless $_[0]->{silent} }
sub error { $_[0]->{error}->(@_) unless $_[0]->{silent} }
sub fatal { $_[0]->{fatal}->(@_) unless $_[0]->{silent} }


package DBIx::Migrator::Migration;

our $dbh;

sub new {
    my $class = shift;
    my %opts  = @_;

    $dbh = $opts{dbh};

    return bless \%opts, $class;
}

sub dbh { $dbh }
sub filename { $_[0]->{filename} }

1;