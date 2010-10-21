package MaRo::Driver::Net::Cassandra;
use strict;
use warnings;
use base qw(MaRo::Driver);

use Net::Cassandra;
use Carp 'croak';
use UNIVERSAL::isa;

__PACKAGE__->mk_accessors(
    qw(client)
);

sub new {
    my ($class, $database) = @_;
    croak "database is required" unless $database;
    my $cassandra = Net::Cassandra->new( hostname => $database->host );
    my $client    = $cassandra->client;
    $class->SUPER::new({client => $client});
}

sub set {
    my ($self, $arg, $value) = @_;
    $self->validate_key_arg($arg);

    eval {
        $self->client->insert(
            'Keyspace1',
            $arg->{key},
            Net::Cassandra::Backend::ColumnPath->new(
                {
                    column_family => $arg->{column_family}, column => $arg->{column} }
            ),
            $value,
            time,
            Net::Cassandra::Backend::ConsistencyLevel::QUORUM
          );
    };
    die $@->why if $@;
    $value;
}

sub get {
    my ($self, $arg) = @_;
    $self->validate_key_arg($arg);
    my $value;
    eval {
        my $what = $self->client->get(
            $arg->{key_space},
            $arg->{key},
            Net::Cassandra::Backend::ColumnPath->new(
                {
                    column_family => $arg->{column_family}, column => $arg->{column} }
            ),
            Net::Cassandra::Backend::ConsistencyLevel::QUORUM
          );
        $value = $what->column->value;
        my $timestamp = $what->column->timestamp;
    };
    return if $@ && $@->isa('Net::Cassandra::Backend::NotFoundException');
    die $@->why if $@;
    $value;
}

sub validate_key_arg {
    my ($self, $arg) = @_;
    foreach (qw{key_space key column_family column}) {
        defined $arg->{$_} or croak "$_ is required.";
    }
    1;
}

1;
