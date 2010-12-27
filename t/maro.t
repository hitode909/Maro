package test::Maro;
use strict;
use warnings;
use base qw(Test::Class);
use Path::Class;
use lib file(__FILE__)->dir->parent->subdir('lib')->stringify;
use lib file(__FILE__)->dir->subdir('lib')->stringify;
use Test::More;
use Maro;
use TestModel;
use Encode;

sub _use : Test(2) {
    use_ok 'Maro';
    use_ok 'TestModel';
}

sub _key_space : Test(1) {
    my $key_space = TestModel::StandardUTF8->key_space;

    is $key_space, 'MaroTest';
}

sub _column_family : Test(1) {
    my $column_family = TestModel::StandardUTF8->column_family;

    is $column_family, 'StandardUTF8';
}

sub _set_param : Test(1) {
    my $entry = TestModel::StandardUTF8->new_by_key('got-new-guitar');
    $entry->body('my guitar is very cool');
    $entry->author('hitodekun');
    is $entry->author, 'hitodekun';
}

sub _new_and_set : Test(3) {
    my $key = rand;
    my $entry = TestModel::StandardUTF8->new_by_key(rand);
    $entry->title('got new guitar');
    $entry->body('my guitar is very cool');
    $entry->author('hitodekun');

    is $entry->title, 'got new guitar';
    is $entry->body, 'my guitar is very cool';
    is $entry->author, 'hitodekun';
}

sub _create : Test(5) {
    my $key = rand;
    my $entry = TestModel::StandardUTF8->create(
        key => $key,
        title => 'poe',
        body => 'poepoe',
        author => 'poepoepoe',
    );
    isa_ok $entry, 'TestModel::StandardUTF8';

    is $entry->key, $key;
    is $entry->title, 'poe';
    is $entry->body, 'poepoe';
    is $entry->author, 'poepoepoe';
}

sub _create_now : Test(4) {
    my $key = rand;
    my $entry = TestModel::SuperTime->create_now(
        key => $key,
        title => 'i',
        body => 'iphone',
    );
    isa_ok $entry, 'TestModel::SuperTime';

    is length $entry->super_column, 16;
    is $entry->title, 'i';
    is $entry->body, 'iphone';
}

sub _create_and_find : Test(4) {
    my $key = rand;
    my $entry = TestModel::StandardUTF8->create(
        key => $key,
        title => 'poe',
        body => 'poepoe',
        author => 'poepoepoe',
    );

    $entry = TestModel::StandardUTF8->find($key);

    is $entry->key, $key;
    is $entry->{title}, 'poe';
    is $entry->{body}, 'poepoe';
    is $entry->{author}, 'poepoepoe';
}

sub _create_and_find_with_super_column : Tests {
    my $key = rand;
    my $super_column = rand;
    my $entry = TestModel::SuperUTF8->create(
        key => $key,
        super_column => $super_column,
        title => 'abc',
        body => 'abcabc',
        author => 'abcabcabc',
    );

    $entry = TestModel::SuperUTF8->find($super_column, $key);
    is $entry->key, $key;
    is $entry->super_column, $super_column;
    is $entry->{title}, 'abc';
    is $entry->{body}, 'abcabc';
    is $entry->{author}, 'abcabcabc';
}

sub _create_with_not_defined_columns : Test(2) {
    my $key = rand;
    my $entry = TestModel::StandardUTF8->create(
        key => $key,
        category => 'fishing',
        title => 'fish',
        body => 'I like fishing.',
        author => 'turio',
    );

    is $entry->category, 'fishing';

    $entry = TestModel::StandardUTF8->find($key);
    is $entry->{category}, 'fishing';
}

sub _user_timeline : Test(8) {
    my $tl = TestModel::StandardTime->find(rand);
    ok $tl;
    for(0..4) {
        $tl->add_value($_);
    }
    is $tl->count, 5;

    for(0..4) {
        is $tl->slice_as_list->[$_]->value, $_;
    }
    $tl->delete;

    is $tl->count, 0;
}

sub _utf8_columns : Test(4) {
    my $key = rand;
    my $title = '社長日記';
    my $body = 'おなかすいた';
    TestModel::StandardUTF8->utf8_columns([qw(title body)]);
    my $entry = TestModel::StandardUTF8->create(
        key => $key,
        title => $title,
        body => $body,
        url => 'http://example.com',
    );

    $entry = TestModel::StandardUTF8->find($key);
    ok $entry;
    ok Encode::is_utf8($entry->title), 'title is utf8';
    ok Encode::is_utf8($entry->body), 'body is utf8';
    ok !Encode::is_utf8($entry->url), 'url is not utf8';
    TestModel::StandardUTF8->utf8_columns([]);
}

sub _updated_on : Test(1) {
    my $key = rand;
    my $entry = TestModel::StandardUTF8->create(
        key => $key,
        title => 'よろしく',
    );

    $entry = TestModel::StandardUTF8->find($key);
    ok ((DateTime->now - $entry->updated_on)->delta_seconds < 10);
}

sub _slice_as_list : Test(12) {
    my $tl = TestModel::StandardTime->find(rand);
    for(0..10) {
        $tl->add_value($_);
    }

    my $list = $tl->slice_as_list(count => 3);
    is $list->length, 3;
    is_deeply $list->map_value->to_a, [0, 1, 2], 'count';
    my $key2 = $list->[2]->name;

    $list = $tl->slice_as_list(start => $key2, count => 5);
    is_deeply $list->map_value->to_a, [2,3,4,5,6], 'count, start';

    my $key6 = $list->[4]->name;
    $list = $tl->slice_as_list(start => $key6, count => 100);
    is_deeply $list->map_value->to_a, [6,7,8,9,10], 'large count';

    $list = $tl->slice_as_list(finish => $key2);
    is_deeply $list->map_value->to_a, [0,1,2], 'finish';

    $list = $tl->slice_as_list(start => $key6, count => 3, reversed => 1);
    is_deeply $list->map_value->to_a, [6,5,4], 'finish(2)';

    $list = $tl->slice_as_list(start => $key2, finish => $key6);
    is_deeply $list->map_value->to_a, [2,3,4,5,6], 'start, finish';

    $list = $tl->slice_as_list(start => $key2, finish => $key6, count => 2);
    is_deeply $list->map_value->to_a, [2,3], 'start, finish, count';

    $list = $tl->slice_as_list(reversed => 1);
    is_deeply $list->map_value->to_a, [10,9,8,7,6,5,4,3,2,1,0], 'reversed';

    $list = $tl->slice_as_list(reversed => 1, count => 3);
    is_deeply $list->map_value->to_a, [10,9,8], 'reversed, count';

    $list = $tl->slice_as_list(reversed => 1, count => 3, start => $key6);
    is_deeply $list->map_value->to_a, [6,5,4], 'reversed, count, start';

    $list = $tl->slice_as_list(reversed => 1, start => $key6, finish => $key2);
    is_deeply $list->map_value->to_a, [6,5,4,3,2], 'reversed, start, finish';

    $tl->delete;
}

sub _slice_as_list_super_column : Tests {
    my $key = rand;
    for(1..9) {
        TestModel::SuperUTF8->create(
            key => $key,
            super_column => rand,
            title => 'entry' . $_,
            body => 'body' . $_,
            author => 'author' . $_,
        );
    }

    my $entries = TestModel::SuperUTF8->slice_as_list(key => $key);
    is $entries->length, 9;
    my $entry = $entries->first;
    isa_ok $entry, 'TestModel::SuperUTF8';

    $entry->title('title modified');

    $entry = TestModel::SuperUTF8->find($entry->super_column, $entry->key);
    is $entry->title, 'title modified';
}

sub _inflate_deflate : Tests {
    my $key = rand;
    TestModel::StandardUTF8->inflate_column(
        michael => {
            deflate => sub { $_[0] . ' is' },
            inflate => sub { $_[0] . ' it.' },
        }
    );

    my $entry = TestModel::StandardUTF8->create(
        key => $key,
        michael => 'This',
    );

    $entry = TestModel::StandardUTF8->find($key);
    is $entry->michael, 'This is it.';
}

sub _datetime_columns : Tests {
    my $key = rand;
    TestModel::StandardUTF8->datetime_columns(qw/created_on/);

    my $now = DateTime->now;
    my $entry = TestModel::StandardUTF8->create(
        key => $key,
        created_on => $now,
        michael => 'hello',
    );
    $entry = TestModel::StandardUTF8->find($key);
    isa_ok $entry->created_on, 'DateTime';
    is $entry->created_on->epoch, $now->epoch;
}

__PACKAGE__->runtests;

1;
