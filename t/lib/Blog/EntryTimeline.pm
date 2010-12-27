package Blog::EntryTimeline;
use strict;
use warnings;
use base qw (Blog::Base);

__PACKAGE__->column_family('EntryTimeline');
__PACKAGE__->utf8_columns([qw(title body)]);

1;
