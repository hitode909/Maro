package Blog::UserTimeline;
use strict;
use warnings;
use base qw (Blog::Base);

__PACKAGE__->column_family('UserTimeline');
__PACKAGE__->schema_type('tupple');

1;
