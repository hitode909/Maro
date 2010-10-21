package Blog::Entry;
use strict;
use warnings;
use base qw (Blog::Base);

__PACKAGE__->column_family('Entry');
__PACKAGE__->columns([qw(author title body url)]);
__PACKAGE__->utf8_columns([qw(title body)]);

1;
