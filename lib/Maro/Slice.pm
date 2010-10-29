package Maro::Slice;
use strict;
use warnings;
use base qw( Class::Accessor::Fast );
use Maro::List;

__PACKAGE__->mk_accessors(qw(target_object per_slice reversed following_column preceding_column empty_slice));

sub new {
    my $class = shift;
    my $args = ref $_[0] eq 'HASH' ? $_[0] : {@_};
    return $class->SUPER::new({ per_slice => 100, %$args});
}

sub items {
    my ($self) = @_;
    return $self->{items} if exists $self->{items};
    return Maro::List->new if $self->empty_slice;

    if (defined $self->following_column) {
        # 最初が指定されてるとき has_nextチェックのために1つ多めに取得する has_prevは明らかに1
        # gollowing_column=3, count=3のとき，[3,4,5,6]がきて，item=[3,4,5], previous_object=3, next_object=6
        my $items = $self->target_object->slice_as_list(
            start => $self->following_column,
            count => $self->per_slice + 1,
            reversed => $self->reversed,
        );
        $self->preceding_column($items->last->name) if $items->length == $self->per_slice + 1;
        $self->{items} = $self->map_if_needed($items->slice(0, $self->per_slice-1));
    } elsif (defined $self->preceding_column) {
        # preceding_column=6, count=3のとき，reverseするので，[6,5,4,3]がきて，item=[3,4,5], previous_object=3, next_object=6．
        # preceding_column自体はitemに入れない．
        my $items = $self->target_object->slice_as_list(
            start => $self->preceding_column,
            count => $self->per_slice + 1,
            reversed => $self->reversed ? 0 : 1,
        );
        $self->following_column($items->first->name) if $items->length == $self->per_slice + 1;
        $self->{items} = $self->map_if_needed($items->slice(1, $items->length-1)->reverse);
    } else {
        # 先頭 count=3のとき，[0,1,2,3]がきて，next_object=3
        my $items = $self->target_object->slice_as_list(
            count => $self->per_slice + 1,
            reversed => $self->reversed,
        );
        $self->preceding_column($items->last->name) if $items->length == $self->per_slice + 1;
        $self->{items} = $self->map_if_needed($items->slice(0, $self->per_slice-1));
    }
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
    return $self->new_empty unless $self->has_next;

    $self->{followings} = $self->new(
        target_object => $self->target_object,
        per_slice => $self->per_slice,
        following_column => $self->preceding_column,
        reversed => $self->reversed,
    );
}

sub precedings {
    my ($self) = @_;
    return $self->new_empty unless $self->has_prev;
    $self->new(
        target_object => $self->target_object,
        per_slice => $self->per_slice,
        preceding_column => $self->following_column,
        reversed => $self->reversed,
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

sub map_if_needed {
    my ($self, $items) = @_;
    if ($self->target_object->reference_class) {
        $items->map(sub { $self->target_object->reference_object($_->value) });
    } else {
        $items;
    }
}

1;
