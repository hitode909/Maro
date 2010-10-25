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
    $self->key_space($arg)->insertColumn($arg->{key}, $arg->{column_family}, $arg->{parent_key} || '', $arg->{column}, $value);
    $value;
}

sub get {
    my ($self, $arg) = @_;
    $self->validate_key_arg($arg);

    # 存在しないキーをgetすると例外が発生するけど，使いにくいので，nullを返す．どういう例外だったかは見てない．
    my $value;
    eval {
        $value = $self->key_space($arg)->getColumnValue($arg->{key}, $arg->{column_family}, $arg->{parent_key} || '', $arg->{column});
    };
    if ($@) { return; }
    Maro::Column->new({name => $arg->{column}, value => $value, timestamp => time});
}

# TODO: 効率化
sub key_space {
    my ($self, $arg) = @_;

    $self->client->getKeyspace($arg->{key_space});
}

sub validate_key_arg {
    my ($self, $arg) = @_;
    foreach (qw{key_space key column_family column}) {
        defined $arg->{$_} or croak "$_ is required.";
    }
    1;
}

1;
