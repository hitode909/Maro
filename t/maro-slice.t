package test::Maro;
use strict;
use warnings;
use base qw(Test::Class);
use Path::Class;
use lib file(__FILE__)->dir->parent->subdir('lib')->stringify;
use lib file(__FILE__)->dir->subdir('lib')->stringify;
use Test::More;
use Maro;
use Blog::UserTimeline;

sub _follow : Tests {
    my $tl = Blog::UserTimeline->find(rand);
    for(0..9) {
        $tl->add_value($_);
    }

    my $slice0 = $tl->slice(per_slice => 3);
    isa_ok $slice0, 'Maro::Slice';
    isa_ok $slice0->items, 'Maro::List';
    is_deeply $slice0->items->map_value->to_a, [0, 1, 2];
    is $slice0->items->length, 3;
    is $slice0->per_slice, 3;
    is $slice0->count, 10;
    ok $slice0->has_next;
    ok not $slice0->has_prev;

    my $slice1 = $slice0->followings;
    isa_ok $slice1, 'Maro::Slice';
    isa_ok $slice1->items, 'Maro::List';
    is_deeply $slice1->items->map_value->to_a, [3, 4, 5];
    is $slice1->items->length, 3;
    is $slice1->per_slice, 3;
    is $slice1->count, 10;
    ok $slice1->has_next;
    ok $slice1->has_prev;

    my $slice2 = $slice1->followings;
    isa_ok $slice2, 'Maro::Slice';
    isa_ok $slice2->items, 'Maro::List';
    is_deeply $slice2->items->map_value->to_a, [6, 7, 8];
    is $slice2->items->length, 3;
    is $slice2->per_slice, 3;
    is $slice2->count, 10;
    ok $slice2->has_next;
    ok $slice2->has_prev;

    my $slice3 = $slice2->followings;
    isa_ok $slice3, 'Maro::Slice';
    isa_ok $slice3->items, 'Maro::List';
    is_deeply $slice3->items->map_value->to_a, [9];
    is $slice3->items->length, 1;
    is $slice3->per_slice, 3;
    is $slice3->count, 10;
    ok not  $slice3->has_next;
    ok $slice3->has_prev;
}

sub _follow_prev : Tests {
    my $tl = Blog::UserTimeline->find(rand);
    for(0..9) {
        $tl->add_value($_);
    }

    my $slice0 = $tl->slice(per_slice => 3);
    $slice0->items;
    my $slice1 = $slice0->followings;
    $slice1->items;
    is_deeply $slice1->precedings->items->map_value->to_a, $slice0->items->map_value->to_a;
    my $slice2 = $slice1->followings;
    $slice2->items;
    is_deeply $slice2->precedings->items->map_value->to_a, $slice1->items->map_value->to_a;
    my $slice3 = $slice2->followings;
    $slice3->items;
}

sub _reverse_follow : Tests {
    my $tl = Blog::UserTimeline->find(rand);
    for(0..9) {
        $tl->add_value($_);
    }

    my $slice0 = $tl->slice(per_slice => 3, reversed => 1);
    isa_ok $slice0, 'Maro::Slice';
    isa_ok $slice0->items, 'Maro::List';
    is_deeply $slice0->items->map_value->to_a, [9, 8, 7];
    is $slice0->items->length, 3;
    is $slice0->per_slice, 3;
    is $slice0->count, 10;
    ok $slice0->has_next;
    ok not $slice0->has_prev;

    my $slice1 = $slice0->followings;
    isa_ok $slice1, 'Maro::Slice';
    isa_ok $slice1->items, 'Maro::List';
    is_deeply $slice1->items->map_value->to_a, [6, 5, 4];
    is $slice1->items->length, 3;
    is $slice1->per_slice, 3;
    is $slice1->count, 10;
    ok $slice1->has_next;
    ok $slice1->has_prev;

    my $slice2 = $slice1->followings;
    isa_ok $slice2, 'Maro::Slice';
    isa_ok $slice2->items, 'Maro::List';
    is_deeply $slice2->items->map_value->to_a, [3, 2, 1];
    is $slice2->items->length, 3;
    is $slice2->per_slice, 3;
    is $slice2->count, 10;
    ok $slice2->has_next;
    ok $slice2->has_prev;

    my $slice3 = $slice2->followings;
    isa_ok $slice3, 'Maro::Slice';
    isa_ok $slice3->items, 'Maro::List';
    is_deeply $slice3->items->map_value->to_a, [0];
    is $slice3->items->length, 1;
    is $slice3->per_slice, 3;
    is $slice3->count, 10;
    ok not  $slice3->has_next;
    ok $slice3->has_prev;
}

sub _reverse_follow_prev : Tests {
    my $tl = Blog::UserTimeline->find(rand);
    for(0..9) {
        $tl->add_value($_);
    }

    my $slice0 = $tl->slice(per_slice => 3, reversed => 1);
    $slice0->items;
    my $slice1 = $slice0->followings;
    $slice1->items;
    is_deeply $slice1->precedings->items->map_value->to_a, $slice0->items->map_value->to_a;
    my $slice2 = $slice1->followings;
    $slice2->items;
    is_deeply $slice2->precedings->items->map_value->to_a, $slice1->items->map_value->to_a;
    my $slice3 = $slice2->followings;
    $slice3->items;
}

sub _empty : Tests {
    my $tl = Blog::UserTimeline->find(rand);

    my $slice = $tl->slice(per_slice => 3);
    for ($slice, $slice->followings, $slice->precedings) {
        isa_ok $_, 'Maro::Slice';
        isa_ok $_->items, 'Maro::List';
        is $_->items->length, 0;
        is $_->count, 0;
        ok not $_->has_next;
        ok not $_->has_prev;
        isa_ok $_->followings, 'Maro::Slice';
        isa_ok $_->precedings, 'Maro::Slice';
    }
}

sub _end : Tests {
    my $tl = Blog::UserTimeline->find(rand);

    for(0..2) {
        $tl->add_value($_);
    }

    my $slice = $tl->slice(per_slice => 3);
    isa_ok $slice, 'Maro::Slice';
    isa_ok $slice->items, 'Maro::List';
    is_deeply $slice->items->map_value->to_a, [0, 1, 2];
    is $slice->items->length, 3;
    is $slice->count, 3;
    ok not $slice->has_next;
    ok not $slice->has_prev;
    isa_ok $slice->followings, 'Maro::Slice';
    isa_ok $slice->precedings, 'Maro::Slice';

    for ($slice->followings, $slice->precedings) {
        isa_ok $_, 'Maro::Slice';
        isa_ok $_->items, 'Maro::List';
        is $_->items->length, 0;
        is $_->count, 3;
        ok not $_->has_next;
        ok not $_->has_prev;
        isa_ok $_->followings, 'Maro::Slice';
        isa_ok $_->precedings, 'Maro::Slice';
    }
}

__PACKAGE__->runtests;

1;
