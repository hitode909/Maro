package Blog::Base;
use strict;
use warnings;
use base qw(MaRo);

__PACKAGE__->db_object('Blog::DataBase');
__PACKAGE__->key_space('MaRoBlog');

1;
