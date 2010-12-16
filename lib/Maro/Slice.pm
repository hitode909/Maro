package Maro::Slice;
use strict;
use warnings;
use base qw( Class::Accessor::Fast );
use Maro::List;

__PACKAGE__->mk_accessors(qw(target_object per_slice reversed following_column preceding_column empty_slice map_code select_code));

sub new {
    my $class = shift;
    my $args = ref $_[0] eq 'HASH' ? $_[0] : {@_};
    return $class->SUPER::new({ per_slice => 100, %$args});
}

sub items {
    my ($self) = @_;
    return $self->{items} if exists $self->{items};
    return Maro::List->new if $self->empty_slice;

    my $count = $self->select_code ? $self->per_slice * 3 : $self->per_slice + 1;
    if (defined $self->following_column) {
        # 最初が指定されてるとき has_nextチェックのために1つ多めに取得する has_prevは明らかに1
        # gollowing_column=3, count=3のとき，[3,4,5,6]がきて，item=[3,4,5], previous_object=3, next_object=6
        my $items = $self->target_object->slice_as_list(
            start => $self->following_column,
            count => $count,
            reversed => $self->reversed,
        );
        # 先にmapしたらおかしくなる!!!!!!!同時にちまちま見る必要がございます!!!!!!!やばい!!!!!!!!!!!!!!!!!!!
        $self->{items} = Maro::List->new;
        $items->each(sub {
             if ($self->{items}->length == $self->per_slice && !$self->preceding_column) {
                 $self->preceding_column($_->name);
             } elsif ($self->{items}->length < $self->per_slice) {
                 my $item = $self->map_item($_);
                 if ($self->select_code_ok($item)) {
                     $self->{items}->push($item);
                 }
             }
        });
    } elsif (defined $self->preceding_column) {

        # # preceding_column=6, count=3のとき，reverseするので，[6,5,4,3]がきて，item=[3,4,5], previous_object=3, next_object=6．
        # # preceding_column自体はitemに入れない．
        my $items = $self->target_object->slice_as_list(
            start => $self->preceding_column,
            count => $count,
            reversed => $self->reversed ? 0 : 1,
        );
        $self->{items} = Maro::List->new;
        $items->each(sub {
             if ($items->length > 0 && $self->{items}->length == 0 && !$self->following_column) {
                 $self->following_column($_->name);
             } elsif ($self->{items}->length < $self->per_slice) {
                 my $item = $self->map_item($_);
                 if ($self->select_code_ok($item)) {
                     $self->{items}->unshift($item);
                 }
             }
        });

    } else {
        # # 先頭 count=3のとき，[0,1,2,3]がきて，next_object=3
        my $items = $self->target_object->slice_as_list(
            count => $count,
            reversed => $self->reversed,
        );
        $self->{items} = Maro::List->new;
        $items->each(sub {
             if ($self->{items}->length == $self->per_slice && !$self->preceding_column) {
                 $self->preceding_column($_->name);
             } elsif ($self->{items}->length < $self->per_slice) {
                 my $item = $self->map_item($_);

                 if ($self->select_code_ok($item)) {
                     $self->{items}->push($item);
                 }
             }
        });

    }
    return $self->{items};
}

# 厳密にはfollowing_columnじゃない場合があるけど，使い方によると思う
sub has_prev {
    my ($self) = @_;
    $self->items;
    !!$self->following_column;
}

sub has_next {
    my ($self) = @_;
    $self->items;
    !!$self->preceding_column;
}

sub count {
    my ($self) = @_;
    return $self->{count} if exists $self->{count};

    $self->{count} = $self->target_object->count;
}

sub followings {
    my ($self) = @_;
    $self->items unless $self->preceding_column or exists $self->{items}; # preceding_column入ってないとき，items一回呼ばないとけない
    return $self->new_empty unless $self->has_next;

    $self->{followings} = $self->new(
        target_object => $self->target_object,
        per_slice => $self->per_slice,
        following_column => $self->preceding_column,
        reversed => $self->reversed,
        select_code => $self->select_code,
    );
}

sub precedings {
    my ($self) = @_;
    $self->items unless $self->following_column or exists $self->{items}; # gollowing_column入ってないとき，items一回呼ばないとけない
    return $self->new_empty unless $self->has_prev;
    $self->new(
        target_object => $self->target_object,
        per_slice => $self->per_slice,
        preceding_column => $self->following_column,
        reversed => $self->reversed,
        select_code => $self->select_code,
    );
}

# private
sub new_empty {
    my ($self) = @_;
    $self->new(
        target_object => $self->target_object,
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
    if ($self->target_object->map_code) {
        return $self->target_object->map_code->($item);
    }
    if ($self->target_object->reference_class) {
        return $self->target_object->reference_object($item->value);
    }
    return $item;
}

1;
