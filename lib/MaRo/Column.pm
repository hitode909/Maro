package MaRo::Column;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(qw(name value timestamp));

sub as_string {
    my ($self) = @_;
    $self->value;
}

1;
