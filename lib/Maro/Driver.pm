package Maro::Driver;
use strict;
use warnings;
use base qw(
    Class::Accessor::Fast Class::Data::Inheritable
);
use Carp 'croak';

# private
sub parse_slice {
    my ($self, $slice) = @_;
    scalar Maro::List->new($slice)->map(sub {
                                     $self->parse_item($_)
                                 });
}

sub parse_item {
    my ($self, $item) = @_;
    if ($item->{column}) {
        bless $item->column, 'Maro::Column';
    } elsif ($item->{super_column}) {
        my $super_column = bless $item->super_column, 'Maro::SuperColumn';
        $super_column->columns($self->parse_slice($super_column->columns));
        $super_column;
    } else {
        bless $item, 'Maro::Column';
    }
}


1;
