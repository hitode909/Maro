package test::Maro::Driver::Net::Cassandra;
use strict;
use warnings;
use base qw(Test::Class);
use Path::Class;
use lib file(__FILE__)->dir->parent->subdir('lib')->stringify;
use lib file(__FILE__)->dir->subdir('lib')->stringify;

use Test::More;
use Test::Exception;
use MaRo::Driver::Net::Cassandra;

sub _new : Test(1) {
    use_ok 'MaRo::Driver::Net::Cassandra';
}

sub _set_get : Test(7) {
    my $driver = MaRo::Driver::Net::Cassandra->new('localhost', 9160);
    my $key = rand;
    ok $driver->set({key_space => 'Keyspace1', column_family => 'Standard2', key => $key, column => 'from'}, 'Shiga');
    my $column = $driver->get({key_space => 'Keyspace1', column_family => 'Standard2', key => $key, column => 'from'});
    isa_ok $column, 'MaRo::Column';
    is $column->value, 'Shiga';
    is $column->name, 'from';
    ok time - $column->timestamp < 10;
    is $driver->get({key_space => 'Keyspace1', column_family => 'Standard2', parent_key => $key, key => 'hitode', column => '___'}), undef;
    ok $driver->delete({key_space => 'Keyspace1', column_family => 'Standard2', key => $key, column => 'from'});
}

sub _slice : Test(10) {
    my $key = rand;
    my $driver = MaRo::Driver::Net::Cassandra->new('localhost', 9160);
    ok $driver->set({key_space => 'Keyspace1', column_family => 'Standard2', key => $key, column => 'from'}, 'Shiga');
    ok $driver->set({key_space => 'Keyspace1', column_family => 'Standard2', key => $key, column => 'age'},  21);
    ok $driver->set({key_space => 'Keyspace1', column_family => 'Standard2', key => $key, column => 'name'}, 'Inoue');

    my $user = $driver->slice_as_hash({key_space => 'Keyspace1', column_family => 'Standard2', key => $key});
    is $user->{from}, 'Shiga';
    is $user->{age}, 21;
    is $user->{name}, 'Inoue';

    ok $driver->delete({key_space => 'Keyspace1', column_family => 'Standard2', key => $key});

    $user = $driver->slice_as_hash({key_space => 'Keyspace1', column_family => 'Standard2', key => $key});
    is $user->{from}, undef;
    is $user->{age}, undef;
    is $user->{name}, undef;
}

sub _describe : Tests(2) {
    my $driver = MaRo::Driver::Net::Cassandra->new('localhost', 9160);
    my $desc = ($driver->describe_keyspace({key_space => 'MaRoBlog'}));
    ok $desc->{Entry};
    is $desc->{Entry}->{Type}, 'Standard';
}

sub _multiget_slice : Test(7) {
    my $driver = MaRo::Driver::Net::Cassandra->new('localhost', 9160);

    my $multiget_empty = $driver->multiget_slice({key_space => 'Keyspace1', column_family => 'Standard2', keys => [qw{dummy1 dummy2 dummy3}], column_names => [qw{dummy1 dummy2}]});
    is_deeply $multiget_empty->{dummy1}, [];

    my @keys;
    for(0..2) {
        my $key = rand;
        push @keys, $key;
        $driver->set({key_space => 'Keyspace1', column_family => 'Standard2', key => $key, column => 'key'  }, $key);
        $driver->set({key_space => 'Keyspace1', column_family => 'Standard2', key => $key, column => 'index'}, $_);
        $driver->set({key_space => 'Keyspace1', column_family => 'Standard2', key => $key, column => 'hello'}, 'hello');
    }
    my $multiget = $driver->multiget_slice({key_space => 'Keyspace1', column_family => 'Standard2', keys => [@keys], column_names => [qw{key index}]});

    for(@keys) {
        isa_ok $multiget->{$_}, 'MaRo::List';
        is $multiget->{$_}->to_hash->{key}, $_;
        $driver->delete({key_space => 'Keyspace1', column_family => 'Standard2', key => $_});
    }
}

__PACKAGE__->runtests;

1;
