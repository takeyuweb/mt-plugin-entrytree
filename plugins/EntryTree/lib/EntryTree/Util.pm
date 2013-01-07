package EntryTree::Util;

use strict;
use utf8;

use base 'Exporter';

our @EXPORT_OK
    = qw( get_parent get_children );

sub get_parent {
    my ( $entry ) = @_;
    return unless $entry;
    return unless $entry->et_parent_id;
    MT->model( 'entry' )->load( $entry->et_parent_id );
}

sub get_children {
    my ( $entry ) = @_;
    return () unless $entry;
    my @children = MT->model( 'entry' )->load( { et_parent_id => $entry->id } );
    return @children;
}

1;
