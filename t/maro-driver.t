package test::Maro::Driver;
use strict;
use warnings;
use base qw(Test::Class);
use Path::Class;
use lib file(__FILE__)->dir->parent->subdir('lib')->stringify;
use lib file(__FILE__)->dir->subdir('lib')->stringify;

use Test::More;
use Test::Exception;

sub _new : Test(setup => 3) {
    use_ok 'Maro::Driver';
    use_ok 'Maro::Driver::Net::Cassandra::libcassandra';
    use_ok 'Maro::Driver::Net::Cassandra';
}

sub _set_get_standard : Test(14) {
    for my $class qw(Maro::Driver::Net::Cassandra Maro::Driver::Net::Cassandra::libcassandra) {
        my $driver = $class->new('localhost', 9160);
        my $key = rand;
        my $name = rand;
        my $value = rand;
        ok $driver->set({key_space => 'MaroTest', column_family => 'StandardUTF8', key => $key, column => $name}, $value), $class . ' set';
        my $got = $driver->get({key_space => 'MaroTest', column_family => 'StandardUTF8', key => $key, column => $name});
        isa_ok $got, 'Maro::Column', $class . ' got Maro::Column';
        is $got->name, $name;
        is $got->value, $value;
        is $driver->get({key_space => 'MaroTest', column_family => 'StandardUTF8', key => $key, column => rand}), undef, $class . ' get undef';
        ok $driver->delete({key_space => 'MaroTest', column_family => 'StandardUTF8', key => $key, column => $name}), $class . ' delete';
        is $driver->get({key_space => 'MaroTest', column_family => 'StandardUTF8', key => $key, column => $name}), undef, $class . ' get deleted';
    }
}

sub _set_get_super : Test(10) {
    for my $class qw(Maro::Driver::Net::Cassandra Maro::Driver::Net::Cassandra::libcassandra) {
        my $driver = $class->new('localhost', 9160);
        my $key = rand;
        my $scn = rand;
        for(0..4) {
            $driver->set({key_space => 'MaroTest', column_family => 'SuperUTF8', key => $key, super_column => $scn, key => $key, column => 'name'.$_}, 'value'.$_);
        }

        my $got = $driver->get({key_space => 'MaroTest', column_family => 'SuperUTF8', key => $key, super_column => $scn});
        isa_ok $got, 'Maro::SuperColumn', $class . ' got Maro::SuperColumn';
        is $got->name, $scn;
        isa_ok $got->columns->first, 'Maro::Column';
        is $got->columns->first->name, 'name0';
        is $got->columns->first->value, 'value0';
    }
}

sub _slice_standard : Test(8) {
    for my $class qw(Maro::Driver::Net::Cassandra Maro::Driver::Net::Cassandra::libcassandra) {
        my $driver = $class->new('localhost', 9160);
        my $key = rand;
        for(0..4) {
            $driver->set({key_space => 'MaroTest', column_family => 'StandardUTF8', key => $key, column => 'name'.$_}, 'value'.$_);
        }
        my $slice = $driver->slice({key_space => 'MaroTest', column_family => 'StandardUTF8', key => $key, count => 3, column => undef, super_column => undef});
        isa_ok $slice, 'Maro::List';
        isa_ok $slice->first, 'Maro::Column';
        is $slice->first->name, 'name0';
        is $slice->first->value, 'value0';
    }
}

sub _slice_super : Test(12) {
    for my $class qw(Maro::Driver::Net::Cassandra Maro::Driver::Net::Cassandra::libcassandra) {
        my $driver = $class->new('localhost', 9160);
        my $key = rand;
        for my $i (0..4) {
            for my $j (0..4) {
                $driver->set({key_space => 'MaroTest', column_family => 'SuperUTF8', key => $key, super_column => 'super_column'.$i, column => join('-', 'name', $i, $j)}, join('-', 'value', $i, $j));
            }
        }
        my $slice = $driver->slice({key_space => 'MaroTest', column_family => 'SuperUTF8', key => $key, count => 3,});
        isa_ok $slice, 'Maro::List';
        isa_ok $slice->first, 'Maro::SuperColumn';
        isa_ok $slice->first->columns, 'Maro::List';
        isa_ok $slice->first->columns->first, 'Maro::Column';
        is $slice->first->columns->first->name, 'name-0-0';
        is $slice->first->columns->first->value, 'value-0-0';
    }
}

sub _count_standard : Test(2) {
    for my $class qw(Maro::Driver::Net::Cassandra Maro::Driver::Net::Cassandra::libcassandra) {
        my $driver = $class->new('localhost', 9160);
        my $key = rand;
        for(0..4) {
            $driver->set({key_space => 'MaroTest', column_family => 'StandardUTF8', key => $key, column => 'name'.$_}, 'value'.$_);
        }
        is $driver->count({key_space => 'MaroTest', column_family => 'StandardUTF8', key => $key}), 5;
    }
}

sub _count_super : Test(4) {
    for my $class qw(Maro::Driver::Net::Cassandra Maro::Driver::Net::Cassandra::libcassandra) {
        my $driver = $class->new('localhost', 9160);
        my $key = rand;
        for my $i (0..4) {
            for my $j (0..3) {
                $driver->set({key_space => 'MaroTest', column_family => 'SuperUTF8', key => $key, super_column => 'super_column'.$i, column => join('-', 'name', $i, $j)}, join('-', 'value', $i, $j));
            }
        }
        is $driver->count({key_space => 'MaroTest', column_family => 'SuperUTF8', key => $key}), 5;
        is $driver->count({key_space => 'MaroTest', column_family => 'SuperUTF8', key => $key, super_column => 'super_column0'}), 4;
    }
}

sub _describe : Test(1) {
    my $driver1 = Maro::Driver::Net::Cassandra->new('localhost', 9160);
    my $driver2 = Maro::Driver::Net::Cassandra::libcassandra->new('localhost', 9160);
    is_deeply $driver1->describe_keyspace({key_space => 'MaroTest'}), $driver2->describe_keyspace({key_space => 'MaroTest'});
}

sub _timeuuid_many : Test(2) {
    use UUID::Tiny;
    for my $class qw(Maro::Driver::Net::Cassandra::libcassandra Maro::Driver::Net::Cassandra) {
        my $driver = $class->new('localhost', 9160);
        my $key = rand;
        for(1..1000) {
            my $column = UUID::Tiny::create_uuid(UUID::Tiny::UUID_V1);
            # warn join(' ', $class, $_, UUID::Tiny::uuid_to_string($column));
            $driver->set({key_space => 'MaroTest', column_family => 'StandardTime', key => $key, column => $column}, 1);
        }
        ok $class;
    }
}

sub _utf8_many : Test(2) {
    for my $class qw(Maro::Driver::Net::Cassandra Maro::Driver::Net::Cassandra::libcassandra) {
        my $driver = $class->new('localhost', 9160);
        my $key = rand;
        for(1..1000) {
            # warn join(' ', $class, $_);
            $driver->set({key_space => 'MaroTest', column_family => 'StandardUTF8', key => $key, column => $_}, 1);
        }
        ok $class;
    }
}

__PACKAGE__->runtests;

1;




