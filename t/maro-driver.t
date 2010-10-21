package test::Maro::Driver;
use strict;
use warnings;
use base qw(Test::Class);
use Path::Class;
use lib file(__FILE__)->dir->parent->subdir('lib')->stringify;
use lib file(__FILE__)->dir->subdir('lib')->stringify;

use Test::More;
use Test::Exception;
use Blog::DataBase;

sub _new : Test(4) {
    use_ok 'MaRo::Driver';
    use_ok 'MaRo::Driver::Net::Cassandra::libcassandra';
    use_ok 'MaRo::Driver::Net::Cassandra';
    use_ok 'Blog::DataBase';
}

sub _set_get : Tests(6) {
    for my $class qw(MaRo::Driver::Net::Cassandra MaRo::Driver::Net::Cassandra::libcassandra) {
        my $driver = $class->new('Blog::DataBase');
        ok $driver->set({key_space => 'Keyspace1', column_family => 'Standard2', key => 'user', column => 'from'}, 'Shiga');
        is $driver->get({key_space => 'Keyspace1', column_family => 'Standard2', key => 'user', column => 'from'}), 'Shiga';
        ok not $driver->get({key_space => 'Keyspace1', column_family => 'Standard2', parent_key => 'user', key => 'hitode', column => '___'});
    }
}

__PACKAGE__->runtests;

1;
