package test::Maro::Driver::Net::Cassandra;
use strict;
use warnings;
use base qw(Test::Class);
use Path::Class;
use lib file(__FILE__)->dir->parent->subdir('lib')->stringify;
use lib file(__FILE__)->dir->subdir('lib')->stringify;

use Test::More;
use Test::Exception;
use Maro::Driver::Net::Cassandra;

sub _new : Test(1) {
    use_ok 'Maro::Driver::Net::Cassandra';
}

sub _set_get : Test(7) {
    my $driver = Maro::Driver::Net::Cassandra->new('localhost', 9160);
    my $key = rand;
    ok $driver->set({key_space => 'Keyspace1', column_family => 'Standard2', key => $key, column => 'from'}, 'Shiga');
    my $column = $driver->get({key_space => 'Keyspace1', column_family => 'Standard2', key => $key, column => 'from'});
    isa_ok $column, 'Maro::Column';
    is $column->value, 'Shiga';
    is $column->name, 'from';
    ok time - $column->timestamp < 10;
    is $driver->get({key_space => 'Keyspace1', column_family => 'Standard2', parent_key => $key, key => 'hitode', column => '___'}), undef;
    ok $driver->delete({key_space => 'Keyspace1', column_family => 'Standard2', key => $key, column => 'from'});
}

sub _set_get_super_column : Tests {
    my $driver = Maro::Driver::Net::Cassandra->new('localhost', 9160);
    my $super_column = rand;
    my $key = rand;
    ok $driver->set({key_space => 'Keyspace1', column_family => 'Super2', super_column => $super_column, key => $key, column => 'from'}, 'Shiga');
    ok $driver->set({key_space => 'Keyspace1', column_family => 'Super2', super_column => $super_column, key => $key, column => 'name'}, 'Sasaki');
    my $got = $driver->get({key_space => 'Keyspace1', column_family => 'Super2', key => $key, super_column => $super_column});
    isa_ok $got, 'Maro::SuperColumn';
    is $got->name, $super_column;
    isa_ok $got->columns, 'Maro::List';
    is $got->columns->length, 2;
    isa_ok $got->columns->first, 'Maro::Column';
    is $got->columns->first->name, 'from';
    ok $driver->delete({key_space => 'Keyspace1', column_family => 'Super2', key => $key, super_column => $super_column});
    $got = $driver->get({key_space => 'Keyspace1', column_family => 'Super2', key => $key, super_column => $super_column});
    is $got, undef;
}

sub _slice : Test(10) {
    my $key = rand;
    my $driver = Maro::Driver::Net::Cassandra->new('localhost', 9160);
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
    my $driver = Maro::Driver::Net::Cassandra->new('localhost', 9160);
    my $desc = ($driver->describe_keyspace({key_space => 'MaroBlog'}));
    ok $desc->{Entry};
    is $desc->{Entry}->{Type}, 'Standard';
}

sub _multiget_slice : Test(7) {
    my $driver = Maro::Driver::Net::Cassandra->new('localhost', 9160);

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
        isa_ok $multiget->{$_}, 'Maro::List';
        is $multiget->{$_}->to_hash->{key}, $_;
        $driver->delete({key_space => 'Keyspace1', column_family => 'Standard2', key => $_});
    }
}

sub _super_column_get_set : Test(7) {
    my $driver = Maro::Driver::Net::Cassandra->new('localhost', 9160);
    my $key = rand;
    my $super_column = rand;
    my $column_name = rand;
    my $value = rand;
    ok $driver->set({key_space => 'Keyspace1', column_family => 'Super2', key => $key, super_column => $super_column, column => $column_name}, $value);
    my $column = $driver->get({key_space => 'Keyspace1', column_family => 'Super2', key => $key, super_column => $super_column, column => $column_name});
    isa_ok $column, 'Maro::Column';
    is $column->value, $value;
    is $column->name,  $column_name;
    ok time - $column->timestamp < 10;
    is $driver->get({key_space => 'Keyspace1', column_family => 'Super2', key => $key, super_column => $super_column, column => $column_name . '_'}), undef;
    ok $driver->delete({key_space => 'Keyspace1', column_family => 'Super2', key => $key, super_column => $super_column, column => $column_name});
}

sub _super_column_slice : Test(10) {
    my $driver = Maro::Driver::Net::Cassandra->new('localhost', 9160);
    my $key = rand;
    my $super_column = rand;
    my $column_name = rand;
    my $value = rand;
    warn "super column $super_column";
    warn "key $key";

    ok $driver->set({key_space => 'Keyspace1', column_family => 'Super2', key => $key, super_column => $super_column, column => 'from'}, 'Shiga');
    ok $driver->set({key_space => 'Keyspace1', column_family => 'Super2', key => $key, super_column => $super_column, column => 'age'},  21);
    ok $driver->set({key_space => 'Keyspace1', column_family => 'Super2', key => $key, super_column => $super_column, column => 'name'}, 'Inoue');

    my $user = $driver->slice_as_hash({key_space => 'Keyspace1', column_family => 'Super2', key => $key, super_column => $super_column});
    is $user->{from}, 'Shiga';
    is $user->{age}, 21;
    is $user->{name}, 'Inoue';

    ok $driver->delete({key_space => 'Keyspace1', column_family => 'Super2', key => $key, super_column => $super_column});

    $user = $driver->slice_as_hash({key_space => 'Keyspace1', column_family => 'Super2', key => $key, super_column => $super_column});
    is $user->{from}, undef;
    is $user->{age}, undef;
    is $user->{name}, undef;
}

sub _super_column_slice_2 : Tests {
    my $driver = Maro::Driver::Net::Cassandra->new('localhost', 9160);
    my $key = rand;
    my $super_column1 = 'a' . rand;
    my $super_column2 = 'b' . rand;
    my $column_name = rand;
    my $value = rand;

    ok $driver->set({key_space => 'Keyspace1', column_family => 'Super2', key => $key, super_column => $super_column1, column => 'from'}, 'Shiga');
    ok $driver->set({key_space => 'Keyspace1', column_family => 'Super2', key => $key, super_column => $super_column1, column => 'age'},  21);
    ok $driver->set({key_space => 'Keyspace1', column_family => 'Super2', key => $key, super_column => $super_column1, column => 'name'}, 'Inoue');

    ok $driver->set({key_space => 'Keyspace1', column_family => 'Super2', key => $key, super_column => $super_column2, column => 'from'}, 'Chiba');
    ok $driver->set({key_space => 'Keyspace1', column_family => 'Super2', key => $key, super_column => $super_column2, column => 'age'},  33);
    ok $driver->set({key_space => 'Keyspace1', column_family => 'Super2', key => $key, super_column => $super_column2, column => 'name'}, 'Yamada');

    my $slice = $driver->slice({key_space => 'Keyspace1', column_family => 'Super2', key => $key});
    isa_ok $slice, 'Maro::List';
    isa_ok $slice->first, 'Maro::SuperColumn';
    is $slice->length, 2;
    isa_ok $slice->first->columns->first, 'Maro::Column';
    is $slice->first->columns->first->name, 'age';
    is $slice->first->columns->first->value, 21;

    ok $driver->delete({key_space => 'Keyspace1', column_family => 'Super2', key => $key});
    ok $driver->delete({key_space => 'Keyspace1', column_family => 'Super2', key => $key});

    $slice = $driver->slice({key_space => 'Keyspace1', column_family => 'Super2', key => $key});
    isa_ok $slice, 'Maro::List';
    is $slice->length, 0;
}

__PACKAGE__->runtests;

1;
