package Maro::Driver::Net::Cassandra::libcassandra;
use strict;
use warnings;
use base qw(Maro::Driver);

use Net::Cassandra::libcassandra;
use Carp 'croak';
use Maro::Column;

__PACKAGE__->mk_accessors(
    qw(client)
);

sub new {
    my ($class, $host, $port) = @_;
    my $client = Net::Cassandra::libcassandra::new($host, $port);
    $class->SUPER::new({client => $client});
}

sub set {
    my ($self, $arg, $value) = @_;
    $self->validate_key_arg($arg);

    $value = '' unless defined $value;
    $self->key_space($arg->{key_space})->insertColumn($arg->{key}, $arg->{column_family}, $arg->{super_column}, $arg->{column}, $value);
    1;
}

# key_space key column_family super_column column
sub get {
    my ($self, $arg) = @_;
    $self->validate_key_arg($arg);

    my $value;
    eval {
        $value = $self->key_space($arg->{key_space})->get($arg->{key}, $arg->{column_family}, $arg->{super_column}, $arg->{column});
    };
    if ($@ =~ qr/NotFoundException/) {
        return;
    }
    return $self->parse_item($value);
}

sub count {
    my ($self, $arg) = @_;
    my $count;
    $self->validate_key_arg($arg);
    eval {
        $count = $self->key_space($arg->{key_space})->getCount($arg->{key}, $arg->{column_family}, $arg->{super_column});
    };
    if ($@ =~ qr/NotFoundException/) {
        return 0;
    }
    $count;
}

sub slice {
    my ($self, $arg) = @_;
    $self->validate_key_arg($arg, 0);

    my $slice;
    eval {
        $slice = $self->key_space($arg->{key_space})->get_slice($arg->{key}, $arg->{column_family}, $arg->{super_column}, $arg->{start}, $arg->{finish}, $arg->{reversed}, $arg->{count});
    };
    if ($@ =~ qr/NotFoundException/) {
        return;
    }
    $self->parse_slice($slice);
}

sub delete {
    my ($self, $arg) = @_;
    $self->validate_key_arg($arg);
    eval {
        $self->key_space($arg->{key_space})->remove($arg->{key}, $arg->{column_family}, $arg->{super_column}, $arg->{column});
    };
    if ($@ =~ qr/NotFoundException/) {
        return;
    }
    1;
}

sub describe_keyspace {
    my ($self, $arg) = @_;
    my $what;
    $self->validate_key_arg($arg);
    eval {
        $what = $self->key_space($arg->{key_space})->getDescription;
    };
    die $@->why if $@;
    $what;
}


# private

# TODO: 効率化
sub key_space {
    my ($self, $key_space_name) = @_;

    $self->client->getKeyspace($key_space_name);
}


sub validate_key_arg {
    my ($self, $arg, $validate) = @_;

    # foreach (qw{key_space key column_family}) {
    #     defined $arg->{$_} or croak "$_ is required.";
    # }
    # unless (defined $validate && !$validate) {
    #     croak "column or super_column is required." unless defined $arg->{column} or defined $arg->{super_column};
    # }


    for (qw{super_column column key start finish}) {
        $arg->{$_} = '' unless defined $arg->{$_};
    }
    $arg->{reversed} = 0 unless defined $arg->{reversed};
    $arg->{count} = 100 unless defined $arg->{count};

    1;
}

1;
