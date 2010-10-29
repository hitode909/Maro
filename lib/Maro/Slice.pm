package Maro::Slice;
use strict;
use warnings;
use base qw( Class::Accessor::Fast );
use Maro::List;

__PACKAGE__->mk_accessors(qw(target_object per_slice start finish reversed following_column preceding_column has_next has_prev next_object previous_object));

sub items {
    my ($self) = @_;
    return $self->{items} if $self->{items};

    if (defined $self->following_column) {
        # 最初が指定されてるとき has_nextチェックのために1つ多めに取得する has_prevは明らかに1
        # gollowing_column=3, count=3のとき，[3,4,5,6]がきて，item=[3,4,5], previous_object=3, next_object=6
        my $items = $self->target_object->slice(
            start => $self->following_column,
            count => $self->per_slice + 1,
            reversed => $self->reversed,
        );
        $self->has_next($items->length == $self->per_slice + 1);
        $self->next_object($items->[$self->per_slice]) if $self->has_next;
        $self->has_prev(1);
        $self->previous_object($items->first);
        $self->{items} = $items->slice(0, $self->per_slice-1);
    } elsif (defined $self->preceding_column) {
        # preceding_column=6, count=3のとき，reverseするので，[6,5,4,3]がきて，item=[3,4,5], previous_object=3, next_object=6．
        # preceding_column自体はitemに入れない．
        my $items = $self->target_object->slice(
            start => $self->preceding_column,
            count => $self->per_slice + 1,
            reversed => $self->reversed ? 0 : 1,
        );
        $self->has_next(1);
        $self->next_object($items->first);
        $self->has_prev($items->length == $self->per_slice + 1);
        $self->previous_object($items->last) if $self->has_prev;
        $self->{items} = $items->slice(1, $items->length-1)->reverse;
    } else {
        # 先頭 count=3のとき，[0,1,2,3]がきて，next_object=3
        my $items = $self->target_object->slice(
            count => $self->per_slice + 1,
            reversed => $self->reversed,
        );
        $self->has_next($items->length == $self->per_slice + 1);
        $self->next_object($items->[$self->per_slice]);
        $self->has_prev(0);
        $self->{items} = $items->slice(0, $self->per_slice-1);
    }
}

sub count {
    my ($self) = @_;
    return $self->{count} if $self->{count};

    $self->{count} = $self->target_object->count;
}

sub per_slice {
    my ($self) = @_;
    $self->{per_slice} = 3;# if (@_ == 2);
    $self->{per_slice} || 3;
}

sub followings {
    my ($self) = @_;
    my $new_self = (ref $self)->new({
        target_object => $self->target_object,
        per_slice => $self->per_slice,
        following_column => $self->next_object && $self->next_object->name,
        reversed => $self->reversed,
    });
}

sub precedings {
    my ($self) = @_;
    my $new_self = (ref $self)->new({
        target_object => $self->target_object,
        per_slice => $self->per_slice,
        preceding_column => $self->has_prev && $self->previous_object->name,
        reversed => $self->reversed,
    });
}

1;
