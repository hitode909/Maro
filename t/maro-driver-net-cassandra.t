package test::Maro::Driver::Net::Cassandra;
use strict;
use warnings;
use base qw(Test::Class);
use Path::Class;
use lib file(__FILE__)->dir->parent->subdir('lib')->stringify;
use lib file(__FILE__)->dir->subdir('lib')->stringify;

use Test::More;
use Test::Exception;
use Blog::DataBase;
use MaRo::Driver::Net::Cassandra;

sub _new : Test(2) {
    use_ok 'MaRo::Driver::Net::Cassandra';
    use_ok 'Blog::DataBase';
}

sub _set_get : Tests(4) {
    my $driver = MaRo::Driver::Net::Cassandra->new('Blog::DataBase');
    my $key = rand;
    ok $driver->set({key_space => 'Keyspace1', column_family => 'Standard2', key => $key, column => 'from'}, 'Shiga');
    is $driver->get({key_space => 'Keyspace1', column_family => 'Standard2', key => $key, column => 'from'}), 'Shiga';
    ok not $driver->get({key_space => 'Keyspace1', column_family => 'Standard2', parent_key => $key, key => 'hitode', column => '___'});
    ok $driver->delete({key_space => 'Keyspace1', column_family => 'Standard2', key => $key, column => 'from'});
}

sub _slice : Test(10) {
    my $key = rand;
    my $driver = MaRo::Driver::Net::Cassandra->new('Blog::DataBase');
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
    my $driver = MaRo::Driver::Net::Cassandra->new('Blog::DataBase');
    my $desc = ($driver->describe_keyspace({key_space => 'MaRoBlog'}));
    ok $desc->{Entry};
    is $desc->{Entry}->{Type}, 'Standard';
}


__PACKAGE__->runtests;

1;
