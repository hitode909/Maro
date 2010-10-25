package Maro;
use strict;
use warnings;
use base qw (Class::Data::Inheritable);
use Carp;
use UUID::Tiny;
use utf8;
use UNIVERSAL::require;
use DateTime;

__PACKAGE__->mk_classdata($_) for qw(driver_class driver_object server_host server_port key_space column_family utf8_columns _is_list _reference_class);
__PACKAGE__->mk_classdata(default_driver_class => 'Maro::Driver::Net::Cassandra');

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

sub slice_as_reference {
    my ($self, %args) = @_;
    croak "reference class not defined" unless $self->_reference_class;
    $self->slice(%args)->map(sub { $self->_reference_class->new_by_key($_->value) });

}

sub add_reference_object {
    my ($self, $object) = @_;
    croak "reference class not defined" unless $self->_reference_class;
    croak "$object is not ${self->_reference_class}" unless $object->isa($self->_reference_class);
    $self->add_value($object->key);
}

sub reference_object {
    my ($self) = @_;
    die "reference class not defined" unless $self->_reference_class;
    $self->_reference_class->find($self->value);
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

sub updated_on {
    my ($self) = @_;
    DateTime->from_epoch(epoch => (reverse sort map {$_->timestamp} @{$self->slice})[0]);
}

sub inflate_column {
    my $class = shift;
    @_ % 2 and croak "You gave me an odd number of parameters to inflate_column()";

    my %args = @_;
    while (my ($col, $as) = each %args) {
        no strict 'refs';
        no warnings 'redefine';

        if (ref $as and ref $as eq 'HASH') {
            for (qw/inflate deflate/) {
                if ($as->{$_} and ref $as->{$_} ne 'CODE') {
                    croak sprintf "parameter '%s' takes only CODE reference", $_
                }
            }

            *{"$class\::$col"} = sub {
                my $self = shift;
                if (@_) {
                    $as->{deflate}
                        ? $self->param( $col => $as->{deflate}->(@_) )
                        : $self->param( $col => @_ );
                } else {
                    $as->{inflate}
                        ? $as->{inflate}->( $self->param($col) )
                        : $self->param( $col );
                }
            }
        } else {
            *{"$class\::$col"} = $class->_column_as_handler($col, $as);
        }
    }
}

sub datetime_columns {
    my $class = shift;
    my @columns = ref $_[0] eq 'ARRAY' ? @$_[0] : @_;

    foreach (@columns) {
        $class->inflate_column(
            $_ => {
                deflate => sub { $_[0] && $_[0]->isa('DateTime') ? shift->epoch : 0 },
                inflate => sub { $_[0] && DateTime->from_epoch(epoch => shift) },
            }
        );
    }
}

sub reference_class {
    my ($class, $reference_class) = @_;
    $class->_reference_class($reference_class);
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
        # TODO: libcassandraはsliceできない
    }
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
    my ($class) = @_;
    return $class->driver_object if $class->driver_object;
    my $driver_class = $class->default_driver_class || $class->driver_class;
    $driver_class->require or croak "Could not load driver ${class->driver_class}: $@";
    $class->driver_object($driver_class->new($class->server_host || 'localhost', $class->server_port || 9160));
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
    my $co = $self->driver->get({
        column => $column,
        $self->default_keys
    });
    my $value = $co ? $co->value : undef;
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