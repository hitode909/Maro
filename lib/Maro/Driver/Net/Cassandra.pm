package Maro::Driver::Net::Cassandra;
use strict;
use warnings;
use base qw(Maro::Driver);

use Net::Cassandra;
use Carp 'croak';
use UNIVERSAL::isa;
use Maro::SuperColumn;
use Maro::Column;
use Maro::List;

__PACKAGE__->mk_accessors(
    qw(client)
);

sub new {
    my ($class, $host, $port) = @_;
    my $cassandra = Net::Cassandra->new( hostname => $host, port => $port );
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
                    column_family => $arg->{column_family}, super_column => $arg->{super_column}, column => $arg->{column} }
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
    my $what;
    eval {
        $what = $self->client->get(
            $arg->{key_space},
            $arg->{key},
            Net::Cassandra::Backend::ColumnPath->new(
                {
                    column_family => $arg->{column_family}, super_column => $arg->{super_column}, column => $arg->{column} }
            ),
            Net::Cassandra::Backend::ConsistencyLevel::QUORUM
          );
    };
    if ($@) {
        return if $@->isa('Net::Cassandra::Backend::NotFoundException');
        die $@->why if $@;
    }
    $self->parse_item($what);
}

sub count {
    my ($self, $arg) = @_;
    my $count;
    eval {
        $count = $self->client->get_count(
            $arg->{key_space},
            $arg->{key},
            Net::Cassandra::Backend::ColumnParent->new(
                {
                    column_family => $arg->{column_family},
                    super_column => $arg->{super_column},
                }
            ),
            Net::Cassandra::Backend::ConsistencyLevel::QUORUM
          );
    };
    die $@->why if $@;
    $count;
}

sub slice {
    my ($self, $arg) = @_;
    my $what;
    eval {
        $what = $self->client->get_slice(
            $arg->{key_space} || '',
            $arg->{key} || '',
            Net::Cassandra::Backend::ColumnParent->new(
                {
                    column_family => $arg->{column_family},
                    super_column => $arg->{super_column},
                }
            ),
            Net::Cassandra::Backend::SlicePredicate->new(
                {
                    slice_range => Net::Cassandra::Backend::SliceRange->new(
                        {
                            start => $arg->{start} || '',
                            finish => $arg->{finish} || '',
                            count => $arg->{count} || 100,
                            reversed => $arg->{reversed} || 0,
                        }
                )
                }
            ),
            Net::Cassandra::Backend::ConsistencyLevel::QUORUM
          );
    };
    die $@->why if $@;
    $self->parse_slice($what);
}

sub multiget_slice {
    my ($self, $arg) = @_;
    my $what;
    eval {
        $what = $self->client->multiget_slice(
            $arg->{key_space},
            $arg->{keys},
            Net::Cassandra::Backend::ColumnParent->new(
                {
                    column_family => $arg->{column_family},
                    super_column => $arg->{super_column},
                }
            ),
            Net::Cassandra::Backend::SlicePredicate->new(
                {
                    column_names => $arg->{column_names}, }
            ),
            Net::Cassandra::Backend::ConsistencyLevel::QUORUM
          );
    };
    die $@->why if $@;
    my $result = {};
    for (keys %$what) {

        $result->{$_} = Maro::List->from_backend_list($what->{$_});
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
                    column_family => $arg->{column_family}, super_column => $arg->{super_column}, column => $arg->{column} }
            ),
            time
        );
    };
    die $@->why if $@;
    1;
}

sub describe_keyspace {
    my ($self, $arg) = @_;
    my $what;
    eval {
        $what = $self->client->describe_keyspace($arg->{key_space});
    };
    die $@->why if $@;
    $what;
}

sub validate_key_arg {
    my ($self, $arg) = @_;
    foreach (qw{key_space key column_family}) {
        defined $arg->{$_} or croak "$_ is required.";
    }
    croak "column or super_column is required." unless defined $arg->{column} or defined $arg->{super_column};
    1;
}

1;
