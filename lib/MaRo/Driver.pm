package MaRo::Driver;
use strict;
use warnings;
use base qw(
    Class::Accessor::Fast Class::Data::Inheritable
);
use Carp 'croak';

sub set {
    my ($self, $arg, $value) = @_;
}

sub get {
    my ($self, $arg) = @_;
}

1;
