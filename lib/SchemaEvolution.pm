package SchemaEvolution;
use Moose;
use MooseX::Has::Sugar;
use MooseX::Types::Moose qw( HashRef Str );

use Config::Tiny;
use DBI;
use SchemaEvolution::Types qw( DBH );
use Try::Tiny;

with 'MooseX::Getopt';

has 'config_file' => (
    traits => [qw( Getopt )],
    isa => Str,
    cmd_aliases => [qw( c config )],
    ro,
    default => 'evolution.ini',
    required
);

sub run {
    my $self = shift;
    my $dbh = $self->_dbh;
    my ($column, $table) = ($self->_version_column, $self->_version_table);
    my ($version) = $dbh->selectrow_arrayref("SELECT $column FROM $table");
    $version
        or die "Could not select version column '$column' from meta table '$table'";
}

has '_config' => (
    ro,
    lazy_build
);

sub _build__config {
    my $self = shift;
    my $tiny = Config::Tiny->new;
    my $config = $tiny->read($self->config_file)
        or die 'Could not open ' . $self->config_file;
    return $config;
}

for my $param (qw(username password dsn)) {
    has "_$param" => (
        ro,
        lazy,
        default => sub { shift->_config->{_}->{$param} }
    );
}

has '_version_table' => (
    ro,
    isa => Str,
    lazy => 1,
    default => sub { shift->_config->{_}->{version_table} || 'schema_version' }
);

has '_version_column' => (
    ro,
    isa => Str,
    lazy => 1,
    default => sub { shift->_config->{_}->{version_column} || 'version' }
);

has '_dbh' => (
    isa => DBH,
    ro,
    lazy_build
);

sub _build__dbh {
    my $self = shift;
    my $dsn = $self->_dsn or die 'Missing required option "dsn"';
    my @args = ($dsn);
    push @args, $self->_username if $self->_username;
    push @args, $self->_password if $self->_password;
    my $dbh = DBI->connect(@args)
        or die "Could not connect to: " . $self->_dsn;
    return $dbh;
}

1;

=head1 NAME

SchemaEvolution - manage the evolution of a database with simple files

=head1 DESCRIPTION

SchemaEvolution is a very basic tool to cope with evolving a database
schema over time. Rather than hook in with any specific framework,
this is nothing more than a single table to track the version of
database, and a set of scripts to move from one version to another.

=head1 METHODS

=head2 run

Runs the schema evolution process, with settings from the configuration
options. This is the entry point of the 'evolve' script.

=cut
