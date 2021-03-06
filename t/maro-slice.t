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

sub _slice_normal_column_utf8 : Tests {
    my $key = rand;
    my $entry = TestModel::StandardUTF8->create(
        key => $key,
    );

    for (0..9) {
        my $method = 'body' . $_;
        $entry->$method($_);
    }

    my $slice0 = TestModel::StandardUTF8->slice(key => $key, per_slice => 3);
    isa_ok $slice0, 'Maro::Slice';
    isa_ok $slice0->items, 'Maro::List';
    is $slice0->items->length, 3;
    is $slice0->items->first->name, 'body0';
    is $slice0->count, 10;
    ok $slice0->has_next;
    ok not $slice0->has_prev;

    my $slice1 = $slice0->followings;
    isa_ok $slice1, 'Maro::Slice';
    isa_ok $slice1->items, 'Maro::List';
    is $slice1->items->length, 3;
    is $slice1->items->first->name, 'body3';
    ok $slice1->has_next;
    ok $slice1->has_prev;

    my $slice2 = $slice1->followings;
    isa_ok $slice2, 'Maro::Slice';
    isa_ok $slice2->items, 'Maro::List';
    is $slice2->items->length, 3;
    is $slice2->items->first->name, 'body6';
    ok $slice2->has_next;
    ok $slice2->has_prev;

    my $slice3 = $slice2->followings;
    isa_ok $slice3, 'Maro::Slice';
    isa_ok $slice3->items, 'Maro::List';
    is $slice3->items->length, 1;
    is $slice3->items->first->name, 'body9';
    is $slice3->per_slice, 3;
    is $slice3->count, 10;
    ok not  $slice3->has_next;
    ok $slice3->has_prev;

}

sub _slice_super_column_timeuuid : Tests {
    my $key = rand;
    for (0..9) {
        TestModel::SuperTime->create_now(
            key => $key,
            title => 'entry' . $_,
            body => 'body' . $_,
            author => 'author' . $_,
        );
    }
    my $slice0 = TestModel::SuperTime->slice(key => $key, per_slice => 3);
    isa_ok $slice0, 'Maro::Slice';
    isa_ok $slice0->items, 'Maro::List';
    is $slice0->items->length, 3;
    is $slice0->items->first->title, 'entry0';
    is $slice0->count, 10;
    ok $slice0->has_next;
    ok not $slice0->has_prev;

    my $slice1 = $slice0->followings;
    isa_ok $slice1, 'Maro::Slice';
    isa_ok $slice1->items, 'Maro::List';
    is $slice1->items->length, 3;
    is $slice1->items->first->title, 'entry3';
    ok $slice1->has_next;
    ok $slice1->has_prev;

    my $slice2 = $slice1->followings;
    isa_ok $slice2, 'Maro::Slice';
    isa_ok $slice2->items, 'Maro::List';
    is $slice2->items->length, 3;
    is $slice2->items->first->title, 'entry6';
    ok $slice2->has_next;
    ok $slice2->has_prev;

    my $slice3 = $slice2->followings;
    isa_ok $slice3, 'Maro::Slice';
    isa_ok $slice3->items, 'Maro::List';
    is $slice3->items->length, 1;
    is $slice2->items->first->title, 'entry6';
    is $slice3->per_slice, 3;
    is $slice3->count, 10;
    ok not  $slice3->has_next;
    ok $slice3->has_prev;
}

sub _slice_super_column_utf8 : Tests {
    my $key = rand;
    for (0..9) {
        my $d = TestModel::SuperUTF8->create(
            key => $key,
            super_column => 'super_column' . $_,
            title => 'entry' . $_,
            body => 'body' . $_,
            author => 'author' . $_,
        );
    }
    my $slice0 = TestModel::SuperUTF8->slice(key => $key, per_slice => 3);
    isa_ok $slice0, 'Maro::Slice';
    isa_ok $slice0->items, 'Maro::List';
    is $slice0->items->length, 3;
    is $slice0->items->first->title, 'entry0';
    is $slice0->count, 10;
    ok $slice0->has_next;
    ok not $slice0->has_prev;

    my $slice1 = $slice0->followings;
    isa_ok $slice1, 'Maro::Slice';
    isa_ok $slice1->items, 'Maro::List';
    is $slice1->items->length, 3;
    is $slice1->items->first->title, 'entry3';
    ok $slice1->has_next;
    ok $slice1->has_prev;

    my $slice2 = $slice1->followings;
    isa_ok $slice2, 'Maro::Slice';
    isa_ok $slice2->items, 'Maro::List';
    is $slice2->items->length, 3;
    is $slice2->items->first->title, 'entry6';
    ok $slice2->has_next;
    ok $slice2->has_prev;

    my $slice3 = $slice2->followings;
    isa_ok $slice3, 'Maro::Slice';
    isa_ok $slice3->items, 'Maro::List';
    is $slice3->items->length, 1;
    is $slice2->items->first->title, 'entry6';
    is $slice3->per_slice, 3;
    is $slice3->count, 10;
    ok not  $slice3->has_next;
    ok $slice3->has_prev;
}

sub _follow : Tests {
    my $tl = TestModel::StandardTime->find(rand);
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

sub _offset : Tests {
    my $tl = TestModel::StandardTime->find(rand);
    for(0..9) {
        $tl->add_value($_);
    }

    my $slice = $tl->slice(per_slice => 3, offset => 3);
    isa_ok $slice, 'Maro::Slice';
    isa_ok $slice->items, 'Maro::List';

    is_deeply $tl->slice(per_slice => 3, offset => 0)->items->map_value->to_a, [0, 1, 2];
    is_deeply $tl->slice(per_slice => 3, offset => 1)->items->map_value->to_a, [1, 2, 3];
    is_deeply $tl->slice(per_slice => 3, offset => 8)->items->map_value->to_a, [8, 9];
    is_deeply $tl->slice(per_slice => 3, offset => 9)->items->map_value->to_a, [9];
    is_deeply $tl->slice(per_slice => 3, offset => 10)->items->map_value->to_a, [];
    is_deeply $tl->slice(per_slice => 3, offset => 11)->items->map_value->to_a, [];
}

sub _offset_select : Tests {
    my $tl = TestModel::StandardTime->find(rand);
    for(0..9) {
        $tl->add_value($_);
    }

    my $slice = $tl->slice(per_slice => 3, offset => 3, select_code => sub { $_->value % 2 == 0 });
    isa_ok $slice, 'Maro::Slice';
    isa_ok $slice->items, 'Maro::List';

    is_deeply $tl->slice(per_slice => 3, offset => 0, select_code => sub { $_->value % 2 == 0 })->items->map_value->to_a, [0, 2, 4];
    is_deeply $tl->slice(per_slice => 3, offset => 1, select_code => sub { $_->value % 2 == 0 })->items->map_value->to_a, [2, 4, 6];
    is_deeply $tl->slice(per_slice => 3, offset => 2, select_code => sub { $_->value % 2 == 0 })->items->map_value->to_a, [4,6,8];
    is_deeply $tl->slice(per_slice => 3, offset => 3, select_code => sub { $_->value % 2 == 0 })->items->map_value->to_a, [6,8];
    is_deeply $tl->slice(per_slice => 3, offset => 4, select_code => sub { $_->value % 2 == 0 })->items->map_value->to_a, [8];
    is_deeply $tl->slice(per_slice => 3, offset => 5, select_code => sub { $_->value % 2 == 0 })->items->map_value->to_a, [];
}

sub _offset_select_follow_prev : Tests {
    my $tl = TestModel::StandardTime->find(rand);
    for(0..13) {
        $tl->add_value($_);
    }

    my $slice = $tl->slice(per_slice => 3, offset => 2, select_code => sub { $_->value % 2 == 0 });
    is_deeply $slice->items->map_value->to_a, [4,6,8];

    is_deeply $slice->followings->items->map_value->to_a, [10, 12];
    is_deeply $slice->followings->precedings->items->map_value->to_a, [4, 6, 8];

    is_deeply $slice->precedings->items->map_value->to_a, [0, 2];
    is_deeply $slice->precedings->followings->items->map_value->to_a, [4, 6, 8];
}

sub _items_with_offset_limit : Tests {
    my $tl = TestModel::StandardTime->find(rand);
    for(0..9) {
        $tl->add_value($_);
    }

    my $slice = $tl->slice;
    is_deeply $slice->items(0, 3)->map_value->to_a, [0, 1, 2];
    is_deeply $slice->items(1, 4)->map_value->to_a, [1, 2, 3, 4];
}

sub _follow_prev : Tests {
    my $tl = TestModel::StandardTime->find(rand);
    for(0..9) {
        $tl->add_value($_);
    }

    my $slice0 = $tl->slice(per_slice => 3);
    ok $slice0->has_next;
    ok not $slice0->has_prev;
    my $slice1 = $slice0->followings;
    ok $slice1->has_next;
    ok $slice1->has_prev;
    is_deeply $slice1->precedings->items->map_value->to_a, $slice0->items->map_value->to_a;
    ok not $slice1->precedings->has_prev;
    ok $slice1->precedings->has_next;
    my $slice2 = $slice1->followings;
    is_deeply $slice2->precedings->items->map_value->to_a, $slice1->items->map_value->to_a;
    ok $slice2->has_next;
    ok $slice2->has_prev;
    my $pp = $slice2->precedings->precedings;
    ok not $pp->has_prev;
    ok $slice2->precedings->precedings->has_next;
    my $slice3 = $slice2->followings;
    ok not $slice3->has_next;
    ok $slice3->has_prev;
}

sub _reverse_follow : Tests {
    my $tl = TestModel::StandardTime->find(rand);
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
    my $tl = TestModel::StandardTime->find(rand);
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
    my $tl = TestModel::StandardTime->find(rand);

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
    my $tl = TestModel::StandardTime->find(rand);

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

sub _map_code : Test(2) {
    my $tl = TestModel::StandardTime->find(rand);
    for(0..9) {
        $tl->add_value($_);
    }

    TestModel::StandardTime->map_code(sub { $_->value * 2; });

    my $slice = $tl->slice(per_slice => 3);
    is_deeply $slice->items->to_a, [0, 2, 4];

    TestModel::StandardTime->map_code(undef);

    $slice = $tl->slice(per_slice => 3);
    is_deeply $slice->items->map_value->to_a, [0, 1, 2];
}

sub _select_code : Test(3) {
    my $tl = TestModel::StandardTime->find(rand);
    for(0..12) {
        $tl->add_value($_);
    }

    my $slice = $tl->slice(per_slice => 3, select_code => sub { $_->value % 2 == 0 });
    is_deeply $slice->items->map_value->to_a, [0, 2, 4];

    $slice = $slice->followings;
    is_deeply $slice->items->map_value->to_a, [6,8,10];

    $slice = $slice->followings;
    is_deeply $slice->items->map_value->to_a, [12];

}

sub _select_code_precedings : Test(3) {
    my $tl = TestModel::StandardTime->find(rand);
    for(0..12) {
        $tl->add_value($_);
    }

    my $slice = $tl->slice(per_slice => 3, select_code => sub { $_->value % 2 == 0 });
    is_deeply $slice->items->map_value->to_a, [0, 2, 4];

    $slice = $slice->followings;
    is_deeply $slice->items->map_value->to_a, [6,8,10];

    $slice = $slice->precedings;
    is_deeply $slice->items->map_value->to_a, [0, 2, 4];

}

__PACKAGE__->runtests;

1;
