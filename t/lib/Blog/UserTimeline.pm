package Blog::UserTimeline;
use strict;
use warnings;
use base qw (Blog::Base);

__PACKAGE__->column_family('UserTimeline');
__PACKAGE__->set_as_list_class;
__PACKAGE__->reference_class('Blog::Entry');

1;
