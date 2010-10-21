package test::Maro::DataBase;
use strict;
use warnings;
use base qw(Test::Class);
use Path::Class;
use lib file(__FILE__)->dir->parent->subdir('lib')->stringify;
use lib file(__FILE__)->dir->subdir('lib')->stringify;

use Test::More;
use Test::Exception;
use Blog::DataBase;

sub _new : Test(1) {
    use_ok 'Blog::DataBase';
}

sub _attributes : Test(3) {
    my $server = Blog::DataBase->server;
    my $host = Blog::DataBase->host;
    my $port = Blog::DataBase->port;
    is $server, 'localhost:9160';
    is $host, 'localhost';
    is $port, 9160;
}

sub _driver : Test(4) {
    my $driver = Blog::DataBase->driver;
    ok $driver;
    isa_ok $driver, 'MaRo::Driver::Net::Cassandra';

    $driver = Blog::DataBase->driver;
    ok $driver;
    isa_ok $driver, 'MaRo::Driver::Net::Cassandra';
}

__PACKAGE__->runtests;

1;
