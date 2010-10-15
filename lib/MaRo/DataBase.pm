package MaRo::DataBase;
use strict;
use warnings;
use base qw (Class::Data::Inheritable);
use Carp;
use UNIVERSAL::require;

__PACKAGE__->mk_classdata($_) for qw(server key_space driver_object driver_class);
__PACKAGE__->mk_classdata(default_driver_class => 'MaRo::Driver::Net::Cassandra::libcassandra');

sub host {
    my ($class) = @_;
    my ($host, $port) = split ':', $class->server;
    $host;
}

sub port {
    my ($class) = @_;
    my ($host, $port) = split ':', $class->server;
    $port;
}

sub driver {
    my ($class) = @_;
    return $class->driver_object if $class->driver_object;
    my $driver_class = $class->driver_class || $class->default_driver_class;
    $driver_class->require or croak "Could not load driver $driver_class: $@";

    my $driver = $driver_class->new($class);
    $class->driver_object($driver);
}



1;
