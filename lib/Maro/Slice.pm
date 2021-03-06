package Maro::Slice;
use strict;
use warnings;
use base qw( Class::Accessor::Fast );
use Maro::List;

__PACKAGE__->mk_accessors(qw(model key super_column per_slice reversed following_column preceding_column empty_slice map_code select_code is_top offset));

sub new {
    my $class = shift;
    my $args = ref $_[0] eq 'HASH' ? $_[0] : {@_};
    return $class->SUPER::new({ per_slice => 100, %$args});
}

sub items {
    my ($self, $offset, $limit) = @_;

    # Query互換
    if (defined $offset || defined $limit) {
        delete $self->{items};
        $self->following_column(undef);
        $self->preceding_column(undef);
        $self->is_top(undef);
        $self->offset($offset);
        $self->per_slice($limit);
    }

    return $self->{items} if exists $self->{items};
    return Maro::List->new if $self->empty_slice;
    if ($self->offset && $self->following_column) {
        warn 'offsetとfollowing_columnが指定されているが，following_columnは無視します';
        $self->following_column(undef);
    }
    if ($self->offset && $self->preceding_column) {
        warn 'offsetとpreceding_columnが指定されているが，preceding_columnは無視します';
        $self->preceding_column(undef);
    }
    return $self->items_with_offset if ($self->offset || 0) > 0;

    my $count = $self->select_code ? $self->per_slice * 3 : $self->per_slice + 1;
    if (defined $self->following_column) {
        # 最初が指定されてるとき has_nextチェックのために1つ多めに取得する has_prev unless is_top
        # following_column=3, count=3のとき，[3,4,5,6]がきて，item=[3,4,5], previous_object=3, next_object=6
        my $items = $self->model->slice_as_list(
            key => $self->key,
            super_column => $self->super_column,
            start => $self->following_column,
            count => $count,
            reversed => $self->reversed,
        );
        $self->{items} = Maro::List->new;
        $items->each(sub {
             if ($self->{items}->length == $self->per_slice && !$self->preceding_column) {
                 $self->preceding_column($_->isa('Maro::Column') ? $_->name : $_->super_column);
             } elsif ($self->{items}->length < $self->per_slice) {
                 my $item = $self->map_item($_);
                 if ($self->select_code_ok($item)) {
                     $self->{items}->push($item);
                 }
             }
        });
        $self->is_top($self->model->slice_as_list(
            key => $self->key,
            super_column => $self->super_column,
            start => $self->following_column,
            count => 2,
            reversed => $self->reversed ? 0 : 1,
        )->length < 2);
    } elsif (defined $self->preceding_column) {

        # # preceding_column=6, count=3のとき，reverseするので，[6,5,4,3,2]がきて，item=[3,4,5], previous_object=3, next_object=6, 2はis_topに使う
        # # preceding_column自体はitemに入れない．
        my $items = $self->model->slice_as_list(
            key => $self->key,
            super_column => $self->super_column,
            start => $self->preceding_column,
            count => $count + 1,
            reversed => $self->reversed ? 0 : 1,
        );
        $self->{items} = Maro::List->new;
        $self->is_top(1);
        $items->shift;
        $items->each(sub {
             if ($self->{items}->length < $self->per_slice) {
                 my $item = $self->map_item($_);
                 if ($self->select_code_ok($item)) {
                     $self->{items}->unshift($item);
                 }
                 if ($self->{items}->length  == $self->per_slice) {
                     $self->following_column($_->isa('Maro::Column') ? $_->name : $_->super_column);
                 }
             } elsif ($self->{items}->length  == $self->per_slice) {
                 $self->is_top(0);
             }
        });

    } else {
        # # 先頭 count=3のとき，[0,1,2,3]がきて，next_object=3
        my $items = $self->model->slice_as_list(
            key => $self->key,
            super_column => $self->super_column,
            count => $count,
            reversed => $self->reversed,
        );
        $self->{items} = Maro::List->new;
        $items->each(sub {
             if ($self->{items}->length == $self->per_slice && !$self->preceding_column) {
                 $self->preceding_column($_->isa('Maro::Column') ? $_->name : $_->super_column);
             } elsif ($self->{items}->length < $self->per_slice) {
                 my $item = $self->map_item($_);

                 if ($self->select_code_ok($item)) {
                     $self->{items}->push($item);
                 }
             }
        });
        $self->is_top(1);

    }
    return $self->{items};
}

# 厳密にはfollowing_columnじゃない場合があるけど，使い方によると思う
sub has_prev {
    my ($self) = @_;
    $self->items;
    !!($self->following_column && !$self->is_top);
}

sub has_next {
    my ($self) = @_;
    $self->items;
    !!$self->preceding_column;
}

sub count {
    my ($self) = @_;

    $self->model->count(
        key => $self->key,
        super_column => $self->super_column
    );
}

sub followings {
    my ($self) = @_;
    $self->items unless $self->preceding_column or exists $self->{items}; # preceding_column入ってないとき，items一回呼ばないとけない
    return $self->new_empty unless $self->has_next;

    $self->{followings} = $self->new(
        model => $self->model,
        key => $self->key,
        super_column => $self->super_column,
        per_slice => $self->per_slice,
        following_column => $self->preceding_column,
        reversed => $self->reversed,
        select_code => $self->select_code,
    );
}

sub precedings {
    my ($self) = @_;
    $self->items unless $self->following_column or exists $self->{items}; # following_column入ってないとき，items一回呼ばないとけない
    return $self->new_empty unless $self->has_prev;
    $self->new(
        key => $self->key,
        super_column => $self->super_column,
        model => $self->model,
        per_slice => $self->per_slice,
        preceding_column => $self->following_column,
        reversed => $self->reversed,
        select_code => $self->select_code,
    );
}

# private

# offset > 0のとき offset分読み飛ばす is_topは0 following, precedingは指定する
sub items_with_offset {
    my ($self) = @_;

    my $count = $self->per_slice + $self->offset + 1;
    $count *= 3 if $self->select_code;

    my $items = $self->model->slice_as_list(
        key => $self->key,
        super_column => $self->super_column,
        start => $self->following_column,
        count => $count,
        reversed => $self->reversed,
    );

    $self->{items} = Maro::List->new;
    my $skip = 0;
    $items->each(sub {
        if ($self->{items}->length == $self->per_slice && !$self->preceding_column) { # 最後の次 = preceding
            $self->preceding_column($_->isa('Maro::Column') ? $_->name : $_->super_column);
        }
        my $item = $self->map_item($_);
        if ($self->{items}->length < $self->per_slice) {
            if ($self->select_code_ok($item)) {
                if ($skip == $self->offset) {
                    if (!$self->following_column) { # following = itemsの先頭
                        $self->following_column($_->isa('Maro::Column') ? $_->name : $_->super_column);
                    }
                    $self->{items}->push($item);
                } else {
                    $skip++;
                }
            }
        }
    });
    return $self->{items};
}

sub new_empty {
    my ($self) = @_;
    $self->new(
        key => $self->key,
        super_column => $self->super_column,
        model => $self->model,
        empty_slice => 1
    );
}

sub select_code_ok {
    my ($self, $item) = @_;

    return 1 unless $self->select_code;
    $self->select_code->($item)
}

sub map_item {
    my ($self, $item)  = @_;
    if ($self->map_code) {
        return $self->map_code->($item);
    }
    if ($self->model->map_code) {
        return $self->model->map_code->($item);
    }
    return $item;
}


1;
