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
use Blog::UserTimeline;
use Encode;

sub _use : Test(2) {
    use_ok 'MaRo';
    use_ok 'Blog::Entry';
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
    is $entry->author, 'hitodekun';
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

sub _create_with_not_defined_columns : Test(2) {
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
    is $entry->{category}, 'fishing';
}

sub _user_timeline : Test(8) {
    my $tl = Blog::UserTimeline->find(rand);
    ok $tl;
    for(0..4) {
        $tl->add_value($_);
    }
    is $tl->count, 5;

    for(0..4) {
        is $tl->slice->[$_]->value, $_;
    }
    $tl->delete;

    is $tl->count, 0;
}

sub _utf8_columns : Test(4) {
    my $key = rand;
    my $title = '社長日記';
    my $body = 'おなかすいた';
    my $entry = Blog::Entry->create(
        key => $key,
        title => $title,
        body => $body,
        url => 'http://example.com',
    );

    $entry = Blog::Entry->find($key);
    ok $entry;
    ok Encode::is_utf8($entry->title), 'title is utf8';
    ok Encode::is_utf8($entry->body), 'body is utf8';
    ok !Encode::is_utf8($entry->url), 'url is not utf8';
}

sub _slice : Test(11) {
    my $tl = Blog::UserTimeline->find(rand);
    for(0..10) {
        $tl->add_value($_);
    }

    my $list = $tl->slice(count => 3);
    is scalar @$list, 3;
    is_deeply [map {$_->value} @$list], [0, 1, 2], 'count';
    my $key2 = $list->[2]->name;

    $list = $tl->slice(start => $key2, count => 5);
    is_deeply [map {$_->value} @$list], [2,3,4,5,6], 'count, start';

    my $key6 = $list->[4]->name;
    $list = $tl->slice(start => $key6, count => 100);
    is_deeply [map {$_->value} @$list], [6,7,8,9,10], 'large count';

    $list = $tl->slice(finish => $key2);
    is_deeply [map {$_->value} @$list], [0,1,2], 'finish';

    $list = $tl->slice(start => $key2, finish => $key6);
    is_deeply [map {$_->value} @$list], [2,3,4,5,6], 'start, finish';

    $list = $tl->slice(start => $key2, finish => $key6, count => 2);
    is_deeply [map {$_->value} @$list], [2,3], 'start, finish, count';

    $list = $tl->slice(reversed => 1);
    is_deeply [map {$_->value} @$list], [10,9,8,7,6,5,4,3,2,1,0], 'reversed';

    $list = $tl->slice(reversed => 1, count => 3);
    is_deeply [map {$_->value} @$list], [10,9,8], 'reversed, count';

    $list = $tl->slice(reversed => 1, count => 3, start => $key6);
    is_deeply [map {$_->value} @$list], [6,5,4], 'reversed, count, start';

    $list = $tl->slice(reversed => 1, start => $key6, finish => $key2);
    is_deeply [map {$_->value} @$list], [6,5,4,3,2], 'reversed, start, finish';


    $tl->delete;
}

__PACKAGE__->runtests;

1;
