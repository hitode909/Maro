package MaRo;
use strict;
use warnings;
use base qw (Class::Data::Inheritable);
use Carp;
use UUID::Tiny;
use utf8;

__PACKAGE__->mk_classdata($_) for qw(db_object key_space column_family columns utf8_columns _is_list);

# public

sub new_by_key {
    my ($class, $key) = @_;
    $class->new(key => $key);
}

sub new {
    my %args = @_[1..$#_];
    return bless \%args, $_[0];
}

sub create {
    my ($class, %params) = @_;
    my $key = delete $params{key};
    croak "no key" unless defined $key;
    my $self = $class->new_by_key($key);

    for my $column (keys %params) {
        $self->$column($params{$column});
    }
    $self;
}

sub find {
    my ($class, $key) = @_;
    my $self = $class->new_by_key($key);
    $self->load_columns if $class->is_object;
    $self;
}

sub set_as_list_class {
    my ($class) = @_;
    $class->_is_list(1);
}

sub is_list {
    my ($class) = @_;
    $class->_is_list;
}

sub is_object {
    my ($class) = @_;
    !$class->_is_list;
}

sub slice {
    my ($self, %args) = @_;
    my $option = {$self->default_keys};
    $option->{count} = $args{count} if defined $args{count};
    $option->{start} = $args{start} if defined $args{start};
    $option->{finish} = $args{finish} if defined $args{finish};
    $option->{reversed} = $args{reversed} if defined $args{reversed};

    $self->driver->slice($option);
}

sub add_value {
    my ($self, $value) = @_;
    $self->set_param(create_UUID(UUID_V1), $value);
}

sub key {
    my ($self) = @_;
    $self->{key};
}

sub delete {
    my ($self) = @_;
    $self->driver->delete({$self->default_keys});
}

sub count {
    my ($self) = @_;
    $self->driver->count({$self->default_keys});
}

# private
sub AUTOLOAD {
    my $self = shift;
    my $method = our $AUTOLOAD;
    $method =~ s/.*:://;
    return if $method eq 'DESTROY';

    $self->param($method, @_);
}

sub load_columns {
    my ($self) = @_;
    if ($self->driver->can("slice_as_hash")) {
        my $values = $self->driver->slice_as_hash({$self->default_keys});
        for (keys %$values) {
            utf8::decode($values->{$_}) if ($self->is_utf8_column($_) and not utf8::is_utf8($values->{$_}));
            $self->{$_} = $values->{$_};
        }
    } else {
        for my $column (@{$self->columns}) {
            $self->$column;
        }
    }
}

sub has_column {
    my $class = shift;
    my $col = shift or return;
    $class->columns or return;
    grep { $col eq $_ } @{$class->columns};
}

sub param {
    if (not defined $_[1]) {
        return;
    }

    if (@_ > 2) {
        my $self = shift;
        @_ % 2 and croak "You gave me an odd number of parameters to param()!";
        my %args = @_;
        $self->{$_} = $args{$_} for (keys %args);
        $self->set_param(%args);
    } else {
        my ($self, $column) = @_;
        $self->get_param($column);
    }
}

sub driver {
    my ($self) = @_;
    $self->_db_object->driver;
}

sub _db_object {
    my ($self) = @_;
    use Blog::DataBase;
    $self->db_object->require or croak "Could not load driver ${self->db_object}: $@";
    $self->db_object;
}

sub default_keys {
    my ($self) = @_;
    return (
        key => $self->key,
        column_family => $self->column_family,
        key_space => $self->key_space,
    );
}

sub is_utf8_column {
    my $class = shift;
    my $col = shift or return;
    my $utf8 = $class->utf8_columns or return;
    ref $utf8 eq 'ARRAY' or return;
    return grep { $_ eq $col } @$utf8;
}

sub get_param {
    my ($self, $column) = @_;
    return $self->{$column} if $self->{$column};
    my $value = $self->driver->get({
        column => $column,
        $self->default_keys
    });
    utf8::decode($value) if ($self->is_utf8_column($column) and not utf8::is_utf8($value));
    $self->{$column} = $value;
}

sub set_param {
    my ($self, $column, $value) = @_;
    $self->driver->set({
        column => $column,
        $self->default_keys,
    }, $value);
}

1;
