package Maro::List;
use strict;
use warnings;
use base qw(List::Rubyish);

our $AUTOLOAD;

sub AUTOLOAD {
    my $self = $_[0];
    my $class = ref($self) || $self;
    $self = undef unless ref($self);
    (my $method = $AUTOLOAD) =~ s!.+::!!;
    return if $method eq 'DESTROY';
    no strict 'refs';
    if ($method =~ /^map_(.+)$/o) {
        *$AUTOLOAD = $class->_map_handler($1);
        goto &$AUTOLOAD;
    }
}

sub _map_handler {
    my $class = shift;
    my $method = shift;
    return sub {
        shift->map(sub { $_->$method() });
    };
}

sub to_hash {
    my ($self) = @_;
    my $hash = {};
    $self->each(sub {
         $hash->{$_->name} = $_->value;
    });
    $hash;
}

sub from_backend_list {
    my ($class, $list) = @_;
    $class->new($list)->map(sub {
         my $column = $_->column;
         Maro::Column->new({name => $column->name, value => $column->value, timestamp => $column->timestamp});
    });
}

1;
