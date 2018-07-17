#
# ██████╗  █████╗ ██╗   ██╗███████╗███╗   ██╗	I
# ██╔══██╗██╔══██╗██║   ██║██╔════╝████╗  ██║	R
# ██████╔╝███████║██║   ██║█████╗  ██╔██╗ ██║	C
# ██╔══██╗██╔══██║╚██╗ ██╔╝██╔══╝  ██║╚██╗██║	d
# ██║  ██║██║  ██║ ╚████╔╝ ███████╗██║ ╚████║	*
# ╚═╝  ╚═╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝╚═╝  ╚═══╝	*
#
#  Raven IRCd - An open-source IRC server written in Perl
#  Copyright (C) 2018  Daniel Hetrick
#  
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#  
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#  
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

package Raven::Config;

use strict;
use XML::TreePP;
use base qw(XML::TreePP);

use vars qw( $VERSION );
$VERSION = '0.43';

my $XML_ENCODING      = 'UTF-8';
my $INTERNAL_ENCODING = 'UTF-8';
my $USER_AGENT        = 'Raven-XML/'.$VERSION.' ';
my $ATTR_PREFIX       = '-';
my $TEXT_NODE_KEY     = '#text';
my $USE_ENCODE_PM     = ( $] >= 5.008 );
my $ALLOW_UTF8_FLAG   = ( $] >= 5.008001 );

my $EMPTY_ELEMENT_TAG_END = ' />';

my $CONFIG_FILE_ID = "raven-xml";
my $NO_RAVEN_ID_ERROR = "Raven configuration file declaration ('raven-xml') not found";

sub set_declaration_id {
    my $self = shift;
    my $id = shift;
    $CONFIG_FILE_ID = $id;
}

sub set_id_error {
    my $self = shift;
    my $err = shift;
    $NO_RAVEN_ID_ERROR = $err;
}

sub parse {
    my $self = shift;
    my $text = ref $_[0] ? ${$_[0]} : $_[0];

    return $self->die( 'Null XML source' ) unless defined $text;

    my $from = &xml_decl_encoding(\$text) || $XML_ENCODING;
    my $to   = $self->{internal_encoding} || $INTERNAL_ENCODING;
    if ( $from && $to ) {
        my $stat = $self->encode_from_to( \$text, $from, $to );
        return $self->die( "Unsupported encoding: $from" ) unless $stat;
    }

    local $self->{__force_array};
    local $self->{__force_array_all};
    if ( exists $self->{force_array} ) {
        my $force = $self->{force_array};
        $force = [$force] unless ref $force;
        $self->{__force_array} = { map { $_ => 1 } @$force };
        $self->{__force_array_all} = $self->{__force_array}->{'*'};
    }

    local $self->{__force_hash};
    local $self->{__force_hash_all};
    if ( exists $self->{force_hash} ) {
        my $force = $self->{force_hash};
        $force = [$force] unless ref $force;
        $self->{__force_hash} = { map { $_ => 1 } @$force };
        $self->{__force_hash_all} = $self->{__force_hash}->{'*'};
    }

    my $tnk = $self->{text_node_key} if exists $self->{text_node_key};
    $tnk = $TEXT_NODE_KEY unless defined $tnk;
    local $self->{text_node_key} = $tnk;

    my $apre = $self->{attr_prefix} if exists $self->{attr_prefix};
    $apre = $ATTR_PREFIX unless defined $apre;
    local $self->{attr_prefix} = $apre;

    if ( exists $self->{use_ixhash} && $self->{use_ixhash} ) {
        return $self->die( "Tie::IxHash is required." ) unless &load_tie_ixhash();
    }

    # Avoid segfaults when receving random input (RT #42441)
    if ( exists $self->{require_xml_decl} && $self->{require_xml_decl} ) {
        return $self->die( "$NO_RAVEN_ID_ERROR" ) unless looks_like_xml(\$text,$CONFIG_FILE_ID);
    }

    my $flat  = $self->xml_to_flat(\$text);
    my $class = $self->{base_class} if exists $self->{base_class};
    my $tree  = $self->flat_to_tree( $flat, '', $class );
    if ( ref $tree ) {
        if ( defined $class ) {
            bless( $tree, $class );
        }
        elsif ( exists $self->{elem_class} && $self->{elem_class} ) {
            bless( $tree, $self->{elem_class} );
        }
    }
    wantarray ? ( $tree, $text ) : $tree;
}

sub xml_decl_encoding {
    my $textref = shift;
    return unless defined $$textref;
    my $args    = looks_like_xml($textref,$CONFIG_FILE_ID) or return;
    my $getcode = ( $args =~ /\s+encoding=(".*?"|'.*?')/ )[0] or return;
    $getcode =~ s/^['"]//;
    $getcode =~ s/['"]$//;
    $getcode;
}

sub looks_like_xml {
    my $textref = shift;
    my $id = shift;
    my $args = ( $$textref =~ /^(?:\s*\xEF\xBB\xBF)?\s*<\?$id(\s+\S.*)\?>/s )[0];
    if ( ! $args ) {
        return;
    }
    return $args;
}


1;
