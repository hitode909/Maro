package Blog::DataBase;
use strict;
use warnings;
use base qw (MaRo::DataBase);

__PACKAGE__->server("localhost:9160");
__PACKAGE__->key_space("Blog");

1;

