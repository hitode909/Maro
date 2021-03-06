package Maro;
use strict;
use warnings;
use base qw (Class::Data::Inheritable);
use Carp;
use UUID::Tiny;
use utf8;
use UNIVERSAL::require;
use DateTime;
use DateTime::Format::MySQL;
use Maro::Slice;

__PACKAGE__->mk_classdata($_) for qw(driver_class driver_object server_host server_port key_space column_family utf8_columns _is_list map_code _is_super_column _describe);
__PACKAGE__->mk_classdata(default_driver_class => 'Maro::Driver::Net::Cassandra::libcassandra');

# public

sub new_by_key {
    my ($class, $key, $super_column) = @_;
    if ($super_column) {
        $class->new(key => $key, super_column => $super_column);
    } else {
        $class->new(key => $key);
    }
}

sub new {
    my %args = @_[1..$#_];
    return bless \%args, $_[0];
}

sub create {
    my ($class, %params) = @_;
    my $key = delete $params{key};
    my $super_column = delete $params{super_column};
    croak "no key" unless defined $key;

    my $self = $super_column ? $class->new_by_key($key, $super_column) : $class->new_by_key($key);

    for my $column (keys %params) {
        $self->$column($params{$column});
    }
    $self;
}

sub create_now {
    my ($class, %params) = @_;
    $class->create(%params, super_column => UUID::Tiny::create_uuid(UUID::Tiny::UUID_V1));
}

sub find {
    my ($class, $key, $super_column) = @_;
    my $self = $class->new_by_key($key, $super_column);
    $self->load_columns if $class->is_object;
    $self;
}

sub is_empty {
    my ($self) = @_;
    $self->count == 0;
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

sub slice_as_list {
    my ($self, %args) = @_;
    my $option = {$self->default_keys};
    $option->{key} = $args{key} if defined $args{key};
    $option->{super_column} = $args{super_column} if defined $args{super_column};
    $option->{count} = $args{count} if defined $args{count};
    $option->{start} = $args{start} if defined $args{start};
    $option->{finish} = $args{finish} if defined $args{finish};
    $option->{reversed} = $args{reversed} if defined $args{reversed};
    my $list = $self->driver->slice($option);
    if ($self->is_super_column) {
        $list->map(sub {
            $self->new_from_super_column($_, $args{key});
        });
    } else {
        $list;
    }
}

sub new_from_super_column {
    my ($class, $super_column, $slice_key) = @_;
    my $self = $class->new(%{$super_column->columns->to_hash}, super_column => $super_column->name, key => $slice_key);
}

sub slice {
    my($self_or_class, %args) = @_;
    my $class = ref $self_or_class || $self_or_class;
    my $args = {model => $class, (%args)};
    if (ref $self_or_class) {
        $args->{key} = $self_or_class->key;
        $args->{super_column} = $self_or_class->super_column;
    }
    Maro::Slice->new($args);
}

sub add_value {
    my ($self, $value) = @_;
    $self->set_param(UUID::Tiny::create_uuid(UUID::Tiny::UUID_V1), $value);
}

sub key {
    my ($self) = @_;
    $self->{key};
}

sub super_column {
    my ($self) = @_;
    $self->{super_column};
}

sub delete {
    my ($self) = @_;
    $self->driver->delete({$self->default_keys});
}

sub delete_column {
    my ($self, $column_name) = @_;
    $self->driver->delete({$self->default_keys, column => $column_name});
    $self->{$column_name} = undef;
}

sub count {
    my ($self, %args) = @_;
    my $option = {$self->default_keys};
    $option->{key} = $args{key} if defined $args{key};
    $option->{super_column} = $args{super_column} if defined $args{super_column};
    $self->driver->count($option);
}

sub updated_on {
    my ($self) = @_;
    DateTime->from_epoch(epoch => (reverse sort map {$_->timestamp} @{$self->slice_as_list})[0]);
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
                deflate => sub {
                    my $v = $_[0];
                    return 0 unless $v;
                    return $v->epoch if UNIVERSAL::isa($v, 'DateTime');
                    eval {
                        return DateTime::Format::MySQL->parse_datetime($v)->epoch;
                    };
                    return 0;
                },
                inflate => sub {
                    $_[0] && DateTime->from_epoch(epoch => shift)
                },
            }
        );
    }
}

# private
sub AUTOLOAD {
    my $self = shift;
    my $method = our $AUTOLOAD;
    $method =~ s/.*:://;
    return if $method eq 'DESTROY';

    $self->param($method, @_);
}

sub is_super_column {
    my ($self) = @_;

    if (defined $self->_is_super_column) {
        return $self->_is_super_column;
    }

    my $described = $self->driver->describe_keyspace({$self->default_keys});
    $self->_is_super_column($self->describe->{Type} eq 'Super');
}

sub describe {
    my ($self) = @_;
    return $self->_describe if defined $self->_describe;
    $self->_describe($self->driver->describe_keyspace({$self->default_keys})->{$self->column_family});
}

sub load_columns {
    my ($self) = @_;
    my $columns;

    if ($self->is_super_column) {
        my $super_column = $self->driver->get({$self->default_keys}); # columnかsupercolumnを返す
        $columns = $super_column->columns;
    } else {
        $columns = $self->driver->slice({$self->default_keys});
    }

    $columns->each(sub {
        my $column = $_;
        my $value = $column->value;
        utf8::decode($value) if ($self->is_utf8_column($column->name) and not utf8::is_utf8($value));
        $self->{$column->name} = $value;
    });
}

sub param {
    if (not defined $_[1]) {
        return;
    }

    if (@_ > 2) {
        my $self = shift;
        @_ % 2 and croak "You gave me an odd number of parameters to param()!";
        my %args = @_;
        for (keys %args) {
            $args{$_} = '' unless defined $args{$_};
            $self->{$_} = $args{$_};
        }
        $self->set_param(%args);
    } else {
        my ($self, $column) = @_;
        $self->get_param($column);
    }
}

sub driver {
    my ($class) = @_;
    return $class->driver_object if $class->driver_object;
    my $driver_class = $class->driver_class || $class->default_driver_class;
    $driver_class->require or croak "Could not load driver $driver_class: $@";
    $class->driver_object($driver_class->new($class->server_host || 'localhost', $class->server_port || 9160));
}

sub default_keys {
    my ($self) = @_;
    if (ref $self) {
        return (
            key => $self->key,
            column_family => $self->column_family,
            key_space => $self->key_space,
            super_column => $self->super_column,
        );
    } else {
        return (
            column_family => $self->column_family,
            key_space => $self->key_space,
        );
    }
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
    return $self->{$column} if exists $self->{$column};
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
    $value = '' unless defined $value;
    $self->driver->set({
        column => $column,
        $self->default_keys,
    }, $value);
}

1;
