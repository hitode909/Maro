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
    my $cassandra = Net::Cassandra->new( hostname => $database->host, port => $database->port );
    my $client    = $cassandra->client;
    $class->SUPER::new({client => $client});
}

sub set {
    my ($self, $arg, $value) = @_;
    $self->validate_key_arg($arg);

    eval {
        $self->client->insert(
            $arg->{key_space},
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
    1;
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
    };
    if ($@) {
        return if $@->isa('Net::Cassandra::Backend::NotFoundException');
        die $@->why if $@;
    }
    $value;
}

# 何を返すべきか．．．．．．．．．
sub slice {
    my ($self, $arg) = @_;
    my $what;
    eval {
        $what = $self->client->get_slice(
            $arg->{key_space},
            $arg->{key},
            Net::Cassandra::Backend::ColumnParent->new(
                {
                    column_family => $arg->{column_family}
                }
            ),
            Net::Cassandra::Backend::SlicePredicate->new(
                {
                    slice_range => Net::Cassandra::Backend::SliceRange->new(
                        {
                            start => $arg->{start} || '', finish => '', count => $arg->{count} || 100 }
                )
                }
            ),
            Net::Cassandra::Backend::ConsistencyLevel::QUORUM
          );
    };
    die $@->why if $@;
    [map { [$_->column->name, $_->column->value]} @$what];
}

sub slice_as_hash {
    my ($self, $arg) = @_;
    my $values = $self->slice($arg);

    my $result = {};
    for (@$values) {
        my ($k, $v) = @$_;
        $result->{$k} = $v;
    }
    $result;
}

sub delete {
    my ($self, $arg) = @_;
    eval {
        $self->client->remove(
            $arg->{key_space},
            $arg->{key},
            Net::Cassandra::Backend::ColumnPath->new(
                {
                    column_family => $arg->{column_family}, column => $arg->{column} }
            ),
            time
        );
    };
    die $@->why if $@;
    1;
}

sub validate_key_arg {
    my ($self, $arg) = @_;
    foreach (qw{key_space key column_family column}) {
        defined $arg->{$_} or croak "$_ is required.";
    }
    1;
}

1;
