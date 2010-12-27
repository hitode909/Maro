package test::Maro::Driver;
use strict;
use warnings;
use base qw(Test::Class);
use Path::Class;
use lib file(__FILE__)->dir->parent->subdir('lib')->stringify;
use lib file(__FILE__)->dir->subdir('lib')->stringify;

use Test::More;
use Test::Exception;

sub _new : Test(3) {
    use_ok 'Maro::Driver';
    use_ok 'Maro::Driver::Net::Cassandra::libcassandra';
    use_ok 'Maro::Driver::Net::Cassandra';
}

sub _set_get : Tests(6) {
    for my $class qw(Maro::Driver::Net::Cassandra Maro::Driver::Net::Cassandra::libcassandra) {
        my $driver = $class->new('localhost', 9160);
        ok $driver->set({key_space => 'MaroTest', column_family => 'StandardUTF8', key => 'user', column => 'from'}, 'Shiga');
        is $driver->get({key_space => 'MaroTest', column_family => 'StandardUTF8', key => 'user', column => 'from'})->value, 'Shiga';
        is $driver->get({key_space => 'MaroTest', column_family => 'StandardUTF8', parent_key => 'user', key => 'hitode', column => '___'}), undef;
    }
}

__PACKAGE__->runtests;

1;
