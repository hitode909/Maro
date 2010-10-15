package test::Maro;
use strict;
use warnings;
use base qw(Test::Class);
use Path::Class;
use lib file(__FILE__)->dir->parent->subdir('lib')->stringify;
use lib file(__FILE__)->dir->subdir('lib')->stringify;
use Test::More;
use MaRo;
use Blog::Entry;

sub _use : Test(2) {
    use_ok 'MaRo';
    use_ok 'Blog::Entry';
}

sub _db_object : Test(1) {
    my $database = Blog::Entry->db_object;
    is $database, 'Blog::DataBase';
}

sub _key_space : Test(1) {
    my $key_space = Blog::Entry->key_space;

    is $key_space, 'MaRoBlog';
}

sub _column_family : Test(1) {
    my $column_family = Blog::Entry->column_family;

    is $column_family, 'Entry';
}

sub _columns : Test(1) {
    my $columns = Blog::Entry->columns;

    is_deeply $columns, [qw(author title body url)];
}

sub _set_param : Test(1) {
    my $entry = Blog::Entry->new_by_key('got-new-guitar');
    $entry->body('my guitar is very cool');
    $entry->author('hitodekun');
}

sub _new_and_set : Test(3) {
    my $key = rand;
    my $entry = Blog::Entry->new_by_key(rand);
    $entry->title('got new guitar');
    $entry->body('my guitar is very cool');
    $entry->author('hitodekun');

    is $entry->title, 'got new guitar';
    is $entry->body, 'my guitar is very cool';
    is $entry->author, 'hitodekun';
}

sub _create : Test(5) {
    my $key = rand;
    my $entry = Blog::Entry->create(
        key => $key,
        title => 'poe',
        body => 'poepoe',
        author => 'poepoepoe',
    );
    isa_ok $entry, 'Blog::Entry';

    is $entry->key, $key;
    is $entry->title, 'poe';
    is $entry->body, 'poepoe';
    is $entry->author, 'poepoepoe';
}

sub _create_and_find : Test(4) {
    my $key = rand;
    my $entry = Blog::Entry->create(
        key => $key,
        title => 'poe',
        body => 'poepoe',
        author => 'poepoepoe',
    );

    $entry = Blog::Entry->find($key);

    is $entry->key, $key;
    is $entry->{title}, 'poe';
    is $entry->{body}, 'poepoe';
    is $entry->{author}, 'poepoepoe';
}

sub _create_with_not_defined_columns : Test(4) {
    my $key = rand;
    my $entry = Blog::Entry->create(
        key => $key,
        category => 'fishing',
        title => 'fish',
        body => 'I like fishing.',
        author => 'turio',
    );

    is $entry->category, 'fishing';

    $entry = Blog::Entry->find($key);
    is $entry->{category}, undef;
    is $entry->category, 'fishing';
    is $entry->{category}, 'fishing';
}


__PACKAGE__->runtests;

1;
