package EntryTree::Plugin;

use strict;
use utf8;

use MT::Util qw( encode_html encode_url remove_html );
use EntryTree::Util qw( get_parent get_children );

our $plugin = MT->component( 'EntryTree' );

sub _system_filters {
    return {
        et_root_entries => {
            label => 'Root Entries',
            items => sub {
                [ { type => 'et_parent', args => { input => '0' } } ],;
            },
            order => 1000,
        },
    };
}

sub _list_properties {
    my $app = MT->instance;
    return {
        et_parent => {
            base    => '__virtual.string',
            label   => 'Entry Parent',
            filter_label => 'Entry Parent ID',
            display => 'default',
            order   => 400,
            html    => sub { parent(@_) },
            raw     => sub { raw_parent( @_ ) },
            terms   => sub {
                my $prop = shift;
                my ( $args, $load_terms, $load_args ) = @_;
                my $value = $args->{input};
                $load_terms->{ et_parent_id } = $value ? $value : 0;
                return;
            },
            filter_tmpl => '<input type="text" class="prop-integer et_parent_id-value text num digit" value="" /> <__trans phrase="__STRING_FILTER_EQUAL" escape="js">',
        },
        et_children => {
            base    => '__virtual.string',
            label   => 'Entry Children',
            display => 'default',
            order   => 401,
            html    => sub { children(@_) },
            raw     => sub { '' },
            filter_editable => 0,
        },
    };
}

sub parent {
    my ( $prop, $obj, $app ) = @_;
    my $parent = get_parent( $obj );
    return '-' unless $parent;
    
    my $parent_text = status_icon( $parent ) . ' ' . encode_html( $parent->title || '...' );
    if ( $app->permissions && $app->permissions->can_edit_entry( $parent, $app->user ) ) {
        my $edit_url = $app->uri(
            mode => 'view',
            args => {
                _type => 'entry',
                blog_id => $parent->blog_id,
                id => $parent->id,
            },
        );
        return '<a href="' . $edit_url . '">' . $parent_text . '</a>';
    } else {
        return $parent_text;
    }
}

sub raw_parent {
    my ( $prop, $obj, $app ) = @_;
    return '' unless $obj;
    return $obj->et_parent_id;
}

sub children {
    my ( $prop, $obj, $app ) = @_;
    my @children = get_children( $obj );
    my @lines = ();
    if ( @children ) {
        push @lines, '<ul>';
        foreach my $child ( @children ) {
            my $child_text = status_icon( $child ) . ' ' . encode_html( $child->title || '...' );
            if ( $app->permissions && $app->permissions->can_edit_entry( $child, $app->user ) ) {
                my $edit_url = $app->uri(
                    mode => 'view',
                    args => {
                        _type => 'entry',
                        blog_id => $child->blog_id,
                        id => $child->id,
                    },
                );
                push @lines, '<li><a href="' . $edit_url . '">' . $child_text . '</a></li>';
            } else {
                push @lines, '<li>' . $child_text . '</li>';
            }
        }
        push @lines, '</ul>';
    }
    
    my $new_entry = MT->model( 'entry' )->new;
    $new_entry->author_id( $app->user->id );
    $new_entry->id( -1 );
    $new_entry->blog_id( $obj->blog_id );
    if ( $app->permissions && $app->permissions->can_edit_entry( $new_entry, $app->user ) ) {
        my $add_text = $plugin->translate( 'Add' );
        my $add_url = $app->uri(
            mode => 'view',
            args => {
                _type => 'entry',
                blog_id => $obj->blog_id,
                et_parent_id => $obj->id,
            },
        );
        my $icon = '<img alt="' . $add_text . '" src="' . MT->static_path . 'images/status_icons/create.gif" />';
        push @lines, $icon . ' <a href="' . $add_url . '" title="' . $plugin->translate( "Add a child of '[_1]'", encode_html( $obj->title ) ) . '">'. $add_text . '</a>';
    }
    if ( @lines ) {
        return join( '', @lines );
    } else {
        return '-';
    }
}

sub status_icon {
    my ( $entry ) = @_;
    my $status = $entry->status;
    my $alt
        = $status == MT::Entry::HOLD()    ? 'Draft'
        : $status == MT::Entry::RELEASE() ? 'Published'
        : $status == MT::Entry::REVIEW()  ? 'Review'
        : $status == MT::Entry::FUTURE()  ? 'Future'
        : $status == MT::Entry::JUNK()    ? 'Junk'
        :                                   '';
    require MT::Entry;
    my $img
        = $status == MT::Entry::HOLD()    ? 'draft.gif'
        : $status == MT::Entry::RELEASE() ? 'success.gif'
        : $status == MT::Entry::REVIEW()  ? 'warning.gif'
        : $status == MT::Entry::FUTURE()  ? 'future.gif'
        : $status == MT::Entry::JUNK()    ? 'warning.gif'
        :                                   '';
    my $icon = '<img alt="' . $alt . '" src="' . MT->static_path . 'images/status_icons/' . $img . '" />';
}

sub _cb_tp_edit_entry {
    my ( $cb, $app, $param, $tmpl ) = @_;
     
    unshift @{ $param->{ field_loop } }, {
        field_id => 'et_parent_id',,
        lock_field => '0',
        field_name => 'et_parent_id',
        show_field => '1',
        field_label => $plugin->translate( 'Entry Parent ID' ),
        label_class => "top-label",
        required => '0',
        field_html => <<'MTML',
<input type="text" name="et_parent_id" value="<mt:var name='et_parent_id' escape='html'>" />
MTML
    };
    
    push @{ $param->{ field_loop } }, {
        field_id => 'et_children',,
        lock_field => '0',
        field_name => 'et_children',
        show_field => '1',
        field_label => $plugin->translate( 'Entry Children' ),
        label_class => "top-label",
        required => '0',
        field_html => <<'MTML',
<mt:If name="id">
    <mt:Entries id="$id" _et_ignore_status="1">
        <ul id="entry-children-list">
            <mt:EntryChildren blog_ids="$blog_id" _et_ignore_status="1">
                <li>id:<mt:EntryID> <mt:EntryTitle escape="html"></li>
            </mt:EntryChildren>
        </ul>
    </mt:Entries>
</mt:If>
MTML
    };
}

sub _cb_entry_post_remove {
    my ( $cb, $entry ) = @_;
    my $parent = get_parent( $entry );
    my @children = get_children( $entry );
    foreach my $child ( @children ) {
        if ( $parent ) {
            $child->et_parent_id( $parent->id );
        } else {
            $child->et_parent_id( 0 );
        }
        $child->save or die $child->errstr;
    }
    return 1;
}

sub _filter_entries_ignore_status {
    my ( $ctx, $args, $cond ) = @_;
    my $terms = $ctx->{ terms };
    delete $terms->{ status };
}


sub _filter_entries_children {
    my ( $ctx, $args, $cond ) = @_;
    my $e = $ctx->stash('entry')
        or return $ctx->_no_entry_error();
    
    if ( $e->id ) {
        my $terms = $ctx->{ terms };
        $terms->{ et_parent_id } = $e->id;
    }
}

sub _filter_et_parent_id {
    my ( $ctx, $args, $cond ) = @_;
    my $et_parent_id = $args->{ et_parent_id };
    $et_parent_id = '0' unless $et_parent_id;
    my $terms = $ctx->{ terms };
    $terms->{ et_parent_id } = $et_parent_id;
}

sub _filter_et_siblings {
    my ( $ctx, $args, $cond ) = @_;
    my $e = $ctx->stash('entry')
        or return $ctx->_no_entry_error();
    
    my $terms = $ctx->{ terms };
    if ( $e->id ) {
        my $filters = $ctx->{ filters };
        push @$filters, sub { 
            return $_[0]->id != $e->id;
        }
    }
    $terms->{ et_parent_id } = $e->et_parent_id;
}

sub _hdlr_entry_children {
    my ( $ctx, $args, $cond ) = @_;
    $args->{ _et_children } = 1;
    $ctx->invoke_handler( 'entries', $args, $cond );
}

sub _hdlr_entry_parent {
    my ( $ctx, $args, $cond ) = @_;
    
    my $e = $ctx->stash('entry')
        or return $ctx->_no_entry_error();
    return '' unless $e->et_parent_id;
    
    $args->{ id } = $e->et_parent_id;
    
    $ctx->invoke_handler( 'entries', $args, $cond );
}

sub _hdlr_entry_siblings {
    my ( $ctx, $args, $cond ) = @_;
    my $e = $ctx->stash('entry')
        or return $ctx->_no_entry_error();
    return '' unless $e->et_parent_id;
    
    $args->{ _et_siblings } = 1;
    $ctx->invoke_handler( 'entries', $args, $cond );
}

sub _hdlr_entry_ancestors {
    my ( $ctx, $args, $cond ) = @_;
    $args->{ _et_ancestors } = 1;
    $ctx->invoke_handler( 'entries', $args, $cond );
}

sub _filter_et_ancestors {
    my ( $ctx, $args, $cond ) = @_;
    my $e = $ctx->stash('entry')
        or return $ctx->_no_entry_error();
    
    my @ids = ();
    my $cursor = $e;
    while ( $cursor = get_parent( $cursor ) ) {
        push @ids, $cursor->id;
    }
    my $terms = $ctx->{ terms };
    $terms->{ id } =\@ids;
}

sub _hdlr_entry_descendants {
    my ( $ctx, $args, $cond ) = @_;
    $args->{ _et_descendants } = 1;
    $ctx->invoke_handler( 'entries', $args, $cond );
}

sub _filter_et_descendants {
    my ( $ctx, $args, $cond ) = @_;
    my $e = $ctx->stash('entry')
        or return $ctx->_no_entry_error();
    
    my @ids = _trace_descendants( $e );
    my $terms = $ctx->{ terms };
    $terms->{ id } =\@ids;
}

sub _trace_descendants {
    my ( $entry ) = @_;
    my @descendant_ids;
    my @children = get_children( $entry );
    foreach my $child ( @children ) {
        push @descendant_ids, $child->id;
        my @ids = _trace_descendants( $child );
        push @descendant_ids, @ids;
    }
    return @descendant_ids;
}

1;
