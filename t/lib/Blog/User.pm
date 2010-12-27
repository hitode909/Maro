package Blog::User;
use strict;
use warnings;
use base qw (Blog::Base);
use Blog::Entry;
use Blog::UserTimeline;

__PACKAGE__->column_family('User');

sub write_entry {
    my ($self, $body) = @_;
    my $key = rand;
    my $entry = Blog::Entry->create(
        key => $key,
        author => $self->key,
        body => $body,
    );

    $entry;
}

sub timeline {
    my ($self) = @_;
    Blog::UserTimeline->find($self->key);
}


1;
