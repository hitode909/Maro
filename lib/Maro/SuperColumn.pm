package Maro::SuperColumn;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(qw(name columns));

sub new {
    my ($self, $args) = @_;
    $self->SUPER::new($args);
}

sub add_column {
    my ($self, $column) = @_;
    $self->columns->push($column);
    $self;
}

1;
