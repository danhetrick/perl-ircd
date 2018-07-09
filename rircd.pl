#!/usr/bin/perl
#   _____                         _____ _____   _____    _ 
#  |  __ \                       |_   _|  __ \ / ____|  | |
#  | |__) |__ ___   _____ _ __     | | | |__) | |     __| |
#  |  _  // _` \ \ / / _ \ '_ \    | | |  _  /| |    / _` |
#  | | \ \ (_| |\ V /  __/ | | |  _| |_| | \ \| |___| (_| |
#  |_|  \_\__,_| \_/ \___|_| |_| |_____|_|  \_\\_____\__,_|
#
#  An IRCd written in Perl with POE
#
# (c) Copyright 2018 Dan Hetrick
#
# Licensed with the same license used by Perl.

# =================
# | MODULES BEGIN |
# =================

use strict;
use warnings;
use POE qw(Component::Server::IRC);
use FindBin qw($RealBin);

# ===============
# | MODULES END |
# ===============

# =================
# | GLOBALS BEGIN |
# =================

# -------------
# | CONSTANTS |
# -------------

use constant AUTH_MASK => 0;
use constant AUTH_PASSWORD => 1;
use constant AUTH_SPOOF => 2;
use constant AUTH_TILDE => 3;

use constant OPERATOR_USERNAME => 0;
use constant OPERATOR_PASSWORD => 1;
use constant OPERATOR_IPMASK => 2;

# -----------
# | SCALARS |
# -----------

my $SERVER_NAME = "perl.irc.server";
my $NICKNAME_LENGTH = 15;
my $SERVER_NETWORK = "PerlNet";
my $MAX_TARGETS = 4;
my $MAX_CHANNELS = 15;
my $SERVER_INFO = "";
my $DEFAULT_PORT = 6667;
my $DEFAULT_AUTH = '*@*';
my $CONFIGURATION_FILE = $RealBin."/ircd.xml";
my $VERBOSE = 1;

# ----------
# | ARRAYS |
# ----------

my @LISTENER_PORTS = ();
my @AUTHS = ();
my @OPERATORS = ();

# ===============
# | GLOBALS END |
# ===============

# ======================
# | MAIN PROGRAM BEGIN |
# ======================

# See if a config file is passed to the program in an argument
if($#ARGV>=0){ $CONFIGURATION_FILE=$ARGV[0]; }

# If no config is found, display error and exit.
if((-e $CONFIGURATION_FILE) && (-f $CONFIGURATION_FILE)){} else {
	print "Configuration file '$CONFIGURATION_FILE' not found.\n";
	exit 1;
}

# Load our config file
load_xml_configuration_file($CONFIGURATION_FILE);

# Display banner to those with verbosity turned on
verbose(logo());
verbose("Using configuration file '$CONFIGURATION_FILE'");

# Make sure we've got enough settings to run
# If not, make sure the default port and auth
# are set; we'll let the user know this happened if
# verbosity is turned on.
check_config_and_apply_defaults();

# Set our server configuration 
my %config = (
    servername => $SERVER_NAME, 
    nicklen    => $NICKNAME_LENGTH,
    network    => $SERVER_NETWORK,
    maxtargets => $MAX_TARGETS,
    maxchannels => $MAX_CHANNELS,
    info => $SERVER_INFO
);

# Spawn our POE::Component::Server::IRC instance
my $pocosi = POE::Component::Server::IRC->spawn( config => \%config );

# Create our POE session
POE::Session->create(
    package_states => [
        'main' => [qw(_start _default)],
    ],
    heap => { ircd => $pocosi },
);

# Start the server!
$poe_kernel->run();

# ====================
# | MAIN PROGRAM END |
# ====================

# ======================
# | SUPPORT CODE BEGIN |
# ======================

# ----------------------
# | POE Event Handlers |
# ----------------------

# _start()
# _default()

# --------------------
# | User Interaction |
# --------------------

# verbose()
# logo()
# display_error_and_exit()
# display_warning()

# -------------------------------
# | Configuration File Handling |
# -------------------------------

# check_config_and_apply_defaults()
# load_xml_configuration_file()
# XML::TreePP
 
sub _start {
    my ($kernel, $heap) = @_[KERNEL, HEAP];
 
    $heap->{ircd}->yield('register', 'all');

    # Add authorized connections
    foreach my $a (@AUTHS){
    	my @entry = @{$a};
    	$heap->{ircd}->add_auth(
        mask     => $entry[AUTH_MASK],
        password     => $entry[AUTH_PASSWORD],
        spoof    => $entry[AUTH_SPOOF],
        no_tilde => $entry[AUTH_TILDE],
    );

    }
 
    # Start up listening port(s)
    foreach my $p (@LISTENER_PORTS){
    	$heap->{ircd}->add_listener(port => $p);
    }
 
    # Add operators
    foreach my $o (@OPERATORS){
		my @entry = @{$o};

		$heap->{ircd}->add_operator(
	        {
	            username => $entry[OPERATOR_USERNAME],
	            password => $entry[OPERATOR_PASSWORD],
	            ipmask => $entry[OPERATOR_IPMASK],
	        }
	    );
	}
}
 
sub _default {
    my ($event, $args) = @_[ARG0 .. $#_];
 
    print "$event: ";
    for my $arg (@$args) {
        if (ref($arg) eq 'ARRAY') {
            print "[", join ( ", ", @$arg ), "] ";
        }
        elsif (ref($arg) eq 'HASH') {
            print "{", join ( ", ", %$arg ), "} ";
        }
        else {
            print "'$arg' ";
        }
    }
 
    print "\n";
 }

# verbose()
# Arguments: 1 (scalar, text to print)
# Returns: Nothing
# Description: Prints text to the console if $VERBOSE is set to 1.
 sub verbose {
	my $txt = shift;

	if($VERBOSE==1){
		print "$txt\n";
	}
}

# logo()
# Arguments: None
# Returns: Scalar
# Description: Returns the text logo for Raven IRCd.
 sub logo {
	return << 'END';
 _____                         _____ _____   _____    _ 
|  __ \                       |_   _|  __ \ / ____|  | |
| |__) |__ ___   _____ _ __     | | | |__) | |     __| |
|  _  // _` \ \ / / _ \ '_ \    | | |  _  /| |    / _` |
| | \ \ (_| |\ V /  __/ | | |  _| |_| | \ \| |___| (_| |
|_|  \_\__,_| \_/ \___|_| |_| |_____|_|  \_\\_____\__,_|
END
}

# display_error_and_exit()
# Arguments: 1 (scalar, error text)
# Returns: Nothing
# Description: Displays an error to the user, and exits the program.
sub display_error_and_exit {
	my $msg = shift;
	print "$msg\n";
	exit 1;
}

# display_warning()
# Arguments: 1 (scalar, warning text)
# Returns: Nothing
# Description: Displays a warning to the user.  If verbosity is turned off,
#              warnings won't be displayed.
sub display_warning {
	my $msg = shift;
	if($VERBOSE==1){
		print "WARNING: $msg\n";
	}
}

# check_config_and_apply_defaults()
# Arguments: None
# Returns: Nothing
# Description: Checks to see if we have enough settings to start up,
#              and if not, supplies enough defaults to start. If the
#              user has not defined any listening ports of auth masks
#              in their config, the defaults (6667 and *@*, respectively),
#              will be used.
 sub check_config_and_apply_defaults {
	if(scalar @LISTENER_PORTS >=1){}else{
		push(@LISTENER_PORTS,$DEFAULT_PORT);
		display_warning("Setting default listening port to $DEFAULT_PORT (missing from configuration file)")
	}
	if(scalar @AUTHS >=1){}else{
		push(@AUTHS,$DEFAULT_AUTH);
		display_warning("Setting default auth to $DEFAULT_AUTH (missing from configuration file)")
	}
}

# load_xml_configuration_file()
# Arguments: 1 (scalar, filename)
# Returns: Nothing
# Description: Opens up an XML config file and reads settings from it.
#              Recursive, so that config files can </import> other
#              config files.
sub load_xml_configuration_file {
	my $filename = shift;

	my $tpp = XML::TreePP->new();
	my $tree = $tpp->parsefile( $filename );

	# ------------------
	# | IMPORT ELEMENT |
	# ------------------
	# <import>filename</import>
	#
	# Allows importing of config files.
	if(ref($tree->{import}) eq 'ARRAY'){
		foreach my $i (@{$tree->{import}}) {
			load_xml_configuration_file($i);
		}
	} elsif($tree->{import}){
		load_xml_configuration_file($tree->{import});
	}

	# --------------------
	# | OPERATOR ELEMENT |
	# --------------------
	# <operator>
	# 	<username>BOB</username>
	# 	<password>CHANGEME</password>
	#	<ipmask>*@*</ipmask>
	# </operator>
	#
	# Adds an operator to the IRC server.
	if(ref($tree->{operator}) eq 'ARRAY'){
		foreach my $a (@{$tree->{operator}}) {
			my @op = ();
			if(ref($a->{username}) eq 'ARRAY'){
				display_error_and_exit("Error in $filename: operator element can't have more than one username element");
			}
			if($a->{username}){
				push(@op,$a->{username});
			} else {
				display_error_and_exit("Error in $filename: operator element missing a username element");
			}

			if(ref($a->{password}) eq 'ARRAY'){
				display_error_and_exit("Error in $filename: operator element can't have more than one password element");
			}
			if($a->{password}){
				push(@op,$a->{password});
			} else {
				display_error_and_exit("Error in $filename: operator element missing a password element");
			}
			
			if(ref($a->{ipmask}) eq 'ARRAY'){
				display_error_and_exit("Error in $filename: operator element can't have more than one ipmask element");
			}
			if($a->{ipmask}){
				push(@op,$a->{ipmask});
			} else {
				push(@op,undef);
			}

			push(@OPERATORS,\@op);

		}
	} elsif($tree->{operator}){
		my @op = ();
		if($tree->{operator}->{username}){
			if(ref($tree->{operator}->{username}) eq 'ARRAY'){
				display_error_and_exit("Error in $filename: operator element can't have more than one username element");
			}
			push (@op,$tree->{operator}->{username});
		} else {
			display_error_and_exit("Error in $filename: operator element missing a username element");
		}
		if($tree->{operator}->{password}){
			if(ref($tree->{operator}->{password}) eq 'ARRAY'){
				display_error_and_exit("Error in $filename: operator element can't have more than one password element");
			}
			push(@op,$tree->{operator}->{password});
		} else {
			display_error_and_exit("Error in $filename: operator element missing a password element");
		}
		if($tree->{operator}->{ipmask}){
			if(ref($tree->{operator}->{ipmask}) eq 'ARRAY'){
				display_error_and_exit("Error in $filename: operator element can't have more than one ipmask element");
			}
			push(@op,$tree->{operator}->{ipmask});
		} else {
			push(@op,undef);
		}

		push(@OPERATORS,\@op);
	}

	# ----------------
	# | AUTH ELEMENT |
	# ----------------
	# <auth>
	# 	<mask>*@*</mask>
	# 	<password>CHANGEME</password>
	# 	<spoof>google.com</spoof>
	# 	<no_tilde>1</no_tilde>
	# </auth>
	#
	# Adds an authorized connection.  Password, spoof, and tilde elements are optional.
	if(ref($tree->{auth}) eq 'ARRAY'){
		foreach my $a (@{$tree->{auth}}) {
			my @auth = ();
			if(ref($a->{mask}) eq 'ARRAY'){
				display_error_and_exit("Error in $filename: auth element can't have more than one mask element");
			}
			if($a->{mask}){
				push(@auth,$a->{mask});
			} else {
				display_error_and_exit("Error in $filename: auth element missing a mask element");
			}
			if(ref($a->{password}) eq 'ARRAY'){
				display_error_and_exit("Error in $filename: auth element can't have more than one password element");
			}
			if($a->{password}){
				push(@auth,$a->{password});
			} else {
				push(@auth,undef);
			}
			if(ref($a->{spoof}) eq 'ARRAY'){
				display_error_and_exit("Error in $filename: auth element can't have more than one spoof element");
			}
			if($a->{spoof}){
				push(@auth,$a->{spoof});
			} else {
				push(@auth,undef);
			}
			if(ref($a->{no_tilde}) eq 'ARRAY'){
				display_error_and_exit("Error in $filename: auth element can't have more than one no_tilde element");
			}
			if($a->{no_tilde}){
				push(@auth,$a->{no_tilde});
			} else {
				push(@auth,undef);
			}
			push(@AUTHS,\@auth);
		}
	} elsif($tree->{auth}){
		my @auth = ();
		if(ref($tree->{auth}->{mask}) eq 'ARRAY'){
			display_error_and_exit("Error in $filename: auth element can't have more than one mask element");
		}
		if($tree->{auth}->{mask}){
			push (@auth,$tree->{auth}->{mask});
		} else {
			display_error_and_exit("Error in $filename: auth element missing a mask element");
		}
		if(ref($tree->{auth}->{password}) eq 'ARRAY'){
			display_error_and_exit("Error in $filename: auth element can't have more than one password element");
		}
		if($tree->{auth}->{password}){
			push(@auth,$tree->{auth}->{password});
		} else {
			push(@auth,undef);
		}
		if(ref($tree->{auth}->{spoof}) eq 'ARRAY'){
			display_error_and_exit("Error in $filename: auth element can't have more than one spoof element");
		}
		if($tree->{auth}->{spoof}){
			push(@auth,$tree->{auth}->{spoof});
		} else {
			push(@auth,undef);
		}
		if(ref($tree->{auth}->{no_tilde}) eq 'ARRAY'){
			display_error_and_exit("Error in $filename: auth element can't have more than one no_tilde element");
		}
		if($tree->{auth}->{no_tilde}){
			push(@auth,$tree->{auth}->{no_tilde});
		} else {
			push(@auth,undef);
		}
		push(@AUTHS,\@auth);
	}

	# ------------------
	# | CONFIG ELEMENT |
	# ------------------
	# <config>
	# 	<verbose>1</verbose>
	# 	<port>6667</port>
	# 	<name>perl.irc.server</name>
	# 	<nicklength>15</nicklength>
	# 	<network>PerlNet</network>
	# 	<max_targets>4</max_targets>
	# 	<max_channels>15</max_channels>
	#	<info>My server info here</info>
	# </config>
	#
	# Allows for server configuration.  Multiple port elements are allowed. All elements are optional;
	# default settings will be used for all missing elements.

	# config->verbose element
	if(ref($tree->{config}->{verbose}) eq 'ARRAY'){
		display_error_and_exit("Error in $filename: config element can't have more than one verbose element");
	} elsif($tree->{config}->{verbose}){
		$VERBOSE = $tree->{config}->{verbose};
	}

	# config->port element
	if(ref($tree->{config}->{port}) eq 'ARRAY'){
		foreach my $p (@{$tree->{config}->{port}}) {
			push(@LISTENER_PORTS,$p);
		}
	} elsif($tree->{config}->{port}){
		push(@LISTENER_PORTS,$tree->{config}->{port});
	}

	# config->name element
	if(ref($tree->{config}->{name}) eq 'ARRAY'){
		display_error_and_exit("Error in $filename: config element can't have more than one name element");
	} elsif($tree->{config}->{name}){
		$SERVER_NAME = $tree->{config}->{name};
	}

	# config->nicklength element
	if(ref($tree->{config}->{nicklength}) eq 'ARRAY'){
		display_error_and_exit("Error in $filename: config element can't have more than one nicklength element");
	} elsif($tree->{config}->{nicklength}){
		$NICKNAME_LENGTH = $tree->{config}->{nicklength};
	}

	# config->network element
	if(ref($tree->{config}->{network}) eq 'ARRAY'){
		display_error_and_exit("Error in $filename: config element can't have more than one network element");
	} elsif($tree->{config}->{network}){
		$SERVER_NETWORK = $tree->{config}->{network};
	}

	# config->max_targets element
	if(ref($tree->{config}->{max_targets}) eq 'ARRAY'){
		display_error_and_exit("Error in $filename: config element can't have more than one max_targets element");
	} elsif($tree->{config}->{max_targets}){
		$MAX_TARGETS = $tree->{config}->{max_targets};
	}

	# config->max_channels element
	if(ref($tree->{config}->{max_channels}) eq 'ARRAY'){
		display_error_and_exit("Error in $filename: config element can't have more than one max_channels element");
	} elsif($tree->{config}->{max_channels}){
		$MAX_CHANNELS = $tree->{config}->{max_channels};
	}

	# config->info element
	if(ref($tree->{config}->{info}) eq 'ARRAY'){
		display_error_and_exit("Error in $filename: config element can't have more than one info element");
	} elsif($tree->{config}->{info}){
		$SERVER_INFO = $tree->{config}->{info};
	}

}

# =======================================================
# | XML::TreePP                                         |
# | By Yusuke Kawasaki                                  |
# | Copyright (c) 2006-2008 Yusuke Kawasaki.            |
# | All rights reserved. This program is free software; |
# | you can redistribute it and/or modify it under the  |
# | same terms as Perl itself.                          |
# =======================================================

package XML::TreePP;
use strict;
use Carp;
use Symbol;

use vars qw( $VERSION );
$VERSION = '0.33';

my $XML_ENCODING      = 'UTF-8';
my $INTERNAL_ENCODING = 'UTF-8';
my $USER_AGENT        = 'XML-TreePP/'.$VERSION.' ';
my $ATTR_PREFIX       = '-';
my $TEXT_NODE_KEY     = '#text';

sub new {
    my $package = shift;
    my $self    = {@_};
    bless $self, $package;
    $self;
}

sub die {
    my $self = shift;
    my $mess = shift;
    return if $self->{ignore_error};
    Carp::croak $mess;
}

sub warn {
    my $self = shift;
    my $mess = shift;
    return if $self->{ignore_error};
    Carp::carp $mess;
}

sub set {
    my $self = shift;
    my $key  = shift;
    my $val  = shift;
    if ( defined $val ) {
        $self->{$key} = $val;
    }
    else {
        delete $self->{$key};
    }
}

sub get {
    my $self = shift;
    my $key  = shift;
    $self->{$key} if exists $self->{$key};
}

sub writefile {
    my $self   = shift;
    my $file   = shift;
    my $tree   = shift or return $self->die( 'Invalid tree' );
    my $encode = shift;
    return $self->die( 'Invalid filename' ) unless defined $file;
    my $text = $self->write( $tree, $encode );
    if ( $] >= 5.008001 && utf8::is_utf8( $text ) ) {
        utf8::encode( $text );
    }
    $self->write_raw_xml( $file, $text );
}

sub write {
    my $self = shift;
    my $tree = shift or return $self->die( 'Invalid tree' );
    my $from = $self->{internal_encoding} || $INTERNAL_ENCODING;
    my $to   = shift || $self->{output_encoding} || $XML_ENCODING;
    my $decl = $self->{xml_decl};
    $decl = '<?xml version="1.0" encoding="' . $to . '" ?>' unless defined $decl;

    local $self->{__first_out};
    if ( exists $self->{first_out} ) {
        my $keys = $self->{first_out};
        $keys = [$keys] unless ref $keys;
        $self->{__first_out} = { map { $keys->[$_] => $_ } 0 .. $#$keys };
    }

    local $self->{__last_out};
    if ( exists $self->{last_out} ) {
        my $keys = $self->{last_out};
        $keys = [$keys] unless ref $keys;
        $self->{__last_out} = { map { $keys->[$_] => $_ } 0 .. $#$keys };
    }

    my $tnk = $self->{text_node_key} if exists $self->{text_node_key};
    $tnk = $TEXT_NODE_KEY unless defined $tnk;
    local $self->{text_node_key} = $tnk;

    my $apre = $self->{attr_prefix} if exists $self->{attr_prefix};
    $apre = $ATTR_PREFIX unless defined $apre;
    local $self->{__attr_prefix_len} = length($apre);
    local $self->{__attr_prefix_rex} = defined $apre ? qr/^\Q$apre\E/s : undef;

    local $self->{__indent};
    if ( exists $self->{indent} && $self->{indent} ) {
        $self->{__indent} = ' ' x $self->{indent};
    }

    my $text = $self->hash_to_xml( undef, $tree );
    if ( $from && $to ) {
        my $stat = $self->encode_from_to( \$text, $from, $to );
        return $self->die( "Unsupported encoding: $to" ) unless $stat;
    }

    return $text if ( $decl eq '' );
    join( "\n", $decl, $text );
}

sub parsehttp {
    my $self = shift;

    local $self->{__user_agent};
    if ( exists $self->{user_agent} ) {
        my $agent = $self->{user_agent};
        $agent .= $USER_AGENT if ( $agent =~ /\s$/s );
        $self->{__user_agent} = $agent if ( $agent ne '' );
    } else {
        $self->{__user_agent} = $USER_AGENT;
    }

    my $http = $self->{__http_module};
    unless ( $http ) {
        $http = $self->find_http_module(@_);
        $self->{__http_module} = $http;
    }
    if ( $http eq 'LWP::UserAgent' ) {
        return $self->parsehttp_lwp(@_);
    }
    elsif ( $http eq 'HTTP::Lite' ) {
        return $self->parsehttp_lite(@_);
    }
    else {
        return $self->die( "LWP::UserAgent or HTTP::Lite is required: $_[1]" );
    }
}

sub find_http_module {
    my $self = shift || {};

    if ( exists $self->{lwp_useragent} && ref $self->{lwp_useragent} ) {
        return 'LWP::UserAgent' if defined $LWP::UserAgent::VERSION;
        return 'LWP::UserAgent' if &load_lwp_useragent();
        return $self->die( "LWP::UserAgent is required: $_[1]" );
    }

    if ( exists $self->{http_lite} && ref $self->{http_lite} ) {
        return 'HTTP::Lite' if defined $HTTP::Lite::VERSION;
        return 'HTTP::Lite' if &load_http_lite();
        return $self->die( "HTTP::Lite is required: $_[1]" );
    }

    return 'LWP::UserAgent' if defined $LWP::UserAgent::VERSION;
    return 'HTTP::Lite'     if defined $HTTP::Lite::VERSION;
    return 'LWP::UserAgent' if &load_lwp_useragent();
    return 'HTTP::Lite'     if &load_http_lite();
    return $self->die( "LWP::UserAgent or HTTP::Lite is required: $_[1]" );
}

sub load_lwp_useragent {
    return $LWP::UserAgent::VERSION if defined $LWP::UserAgent::VERSION;
    local $@;
    eval { require LWP::UserAgent; };
    $LWP::UserAgent::VERSION;
}

sub load_http_lite {
    return $HTTP::Lite::VERSION if defined $HTTP::Lite::VERSION;
    local $@;
    eval { require HTTP::Lite; };
    $HTTP::Lite::VERSION;
}

sub load_tie_ixhash {
    return $Tie::IxHash::VERSION if defined $Tie::IxHash::VERSION;
    local $@;
    eval { require Tie::IxHash; };
    $Tie::IxHash::VERSION;
}

sub parsehttp_lwp {
    my $self   = shift;
    my $method = shift or return $self->die( 'Invalid HTTP method' );
    my $url    = shift or return $self->die( 'Invalid URL' );
    my $body   = shift;
    my $header = shift;

    my $ua = $self->{lwp_useragent} if exists $self->{lwp_useragent};
    if ( ! ref $ua ) {
        $ua = LWP::UserAgent->new();
        $ua->timeout(10);
        $ua->env_proxy();
        $ua->agent( $self->{__user_agent} ) if defined $self->{__user_agent};
    } else {
        $ua->agent( $self->{__user_agent} ) if exists $self->{user_agent};
    }

    my $req = HTTP::Request->new( $method, $url );
    my $ct = 0;
    if ( ref $header ) {
        foreach my $field ( sort keys %$header ) {
            my $value = $header->{$field};
            $req->header( $field => $value );
            $ct ++ if ( $field =~ /^Content-Type$/i );
        }
    }
    if ( defined $body && ! $ct ) {
        $req->header( 'Content-Type' => 'application/x-www-form-urlencoded' );
    }
    $req->content($body) if defined $body;
    my $res = $ua->request($req);
    my $code = $res->code();
    my $text = $res->content();
    my $tree = $self->parse( \$text ) if $res->is_success();
    wantarray ? ( $tree, $text, $code ) : $tree;
}

sub parsehttp_lite {
    my $self   = shift;
    my $method = shift or return $self->die( 'Invalid HTTP method' );
    my $url    = shift or return $self->die( 'Invalid URL' );
    my $body   = shift;
    my $header = shift;

    my $http = HTTP::Lite->new();
    $http->method($method);
    my $ua = 0;
    if ( ref $header ) {
        foreach my $field ( sort keys %$header ) {
            my $value = $header->{$field};
            $http->add_req_header( $field, $value );
            $ua ++ if ( $field =~ /^User-Agent$/i );
        }
    }
    if ( defined $self->{__user_agent} && ! $ua ) {
        $http->add_req_header( 'User-Agent', $self->{__user_agent} );
    }
    $http->{content} = $body if defined $body;
    my $code = $http->request($url) or return;
    my $text = $http->body();
    my $tree = $self->parse( \$text );
    wantarray ? ( $tree, $text, $code ) : $tree;
}

sub parsefile {
    my $self = shift;
    my $file = shift;
    return $self->die( 'Invalid filename' ) unless defined $file;
    my $text = $self->read_raw_xml($file);
    $self->parse( \$text );
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

sub xml_to_flat {
    my $self    = shift;
    my $textref = shift;    # reference
    my $flat    = [];
    my $prefix = $self->{attr_prefix};
    my $ixhash = ( exists $self->{use_ixhash} && $self->{use_ixhash} );

    while ( $$textref =~ m{
        ([^<]*) <
        ((
            \? ([^<>]*) \?
        )|(
            \!\[CDATA\[(.*?)\]\]
        )|(
            \!DOCTYPE\s+([^\[\]<>]*(?:\[.*?\]\s*)?)
        )|(
            \!--(.*?)--
        )|(
            ([^\!\?\s<>](?:"[^"]*"|'[^']*'|[^"'<>])*)
        ))
        > ([^<]*)
    }sxg ) {
        my (
            $ahead,     $match,    $typePI,   $contPI,   $typeCDATA,
            $contCDATA, $typeDocT, $contDocT, $typeCmnt, $contCmnt,
            $typeElem,  $contElem, $follow
          )
          = ( $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13 );
        if ( defined $ahead && $ahead =~ /\S/ ) {
            $ahead =~ s/([^\040-\076])/sprintf("\\x%02X",ord($1))/eg;
            $self->warn( "Invalid string: [$ahead] before <$match>" );
        }

        if ($typeElem) {                        # Element
            my $node = {};
            if ( $contElem =~ s#^/## ) {
                $node->{endTag}++;
            }
            elsif ( $contElem =~ s#/$## ) {
                $node->{emptyTag}++;
            }
            else {
                $node->{startTag}++;
            }
            $node->{tagName} = $1 if ( $contElem =~ s#^(\S+)\s*## );
            unless ( $node->{endTag} ) {
                my $attr;
                while ( $contElem =~ m{
                    ([^\s\=\"\']+)=(?:(")(.*?)"|'(.*?)')
                }sxg ) {
                    my $key = $1;
                    my $val = &xml_unescape( $2 ? $3 : $4 );
                    if ( ! ref $attr ) {
                        $attr = {};
                        tie( %$attr, 'Tie::IxHash' ) if $ixhash;
                    }
                    $attr->{$prefix.$key} = $val;
                }
                $node->{attributes} = $attr if ref $attr;
            }
            push( @$flat, $node );
        }
        elsif ($typeCDATA) {    ## CDATASection
            if ( exists $self->{cdata_scalar_ref} && $self->{cdata_scalar_ref} ) {
                push( @$flat, \$contCDATA );    # as reference for scalar
            }
            else {
                push( @$flat, $contCDATA );     # as scalar like text node
            }
        }
        elsif ($typeCmnt) {                     # Comment (ignore)
        }
        elsif ($typeDocT) {                     # DocumentType (ignore)
        }
        elsif ($typePI) {                       # ProcessingInstruction (ignore)
        }
        else {
            $self->warn( "Invalid Tag: <$match>" );
        }
        if ( $follow =~ /\S/ ) {                # text node
            my $val = &xml_unescape($follow);
            push( @$flat, $val );
        }
    }
    $flat;
}

sub flat_to_tree {
    my $self   = shift;
    my $source = shift;
    my $parent = shift;
    my $class  = shift;
    my $tree   = {};
    my $text   = [];

    if ( exists $self->{use_ixhash} && $self->{use_ixhash} ) {
        tie( %$tree, 'Tie::IxHash' );
    }

    while ( scalar @$source ) {
        my $node = shift @$source;
        if ( !ref $node || UNIVERSAL::isa( $node, "SCALAR" ) ) {
            push( @$text, $node );              # cdata or text node
            next;
        }
        my $name = $node->{tagName};
        if ( $node->{endTag} ) {
            last if ( $parent eq $name );
            return $self->die( "Invalid tag sequence: <$parent></$name>" );
        }
        my $elem = $node->{attributes};
        my $forcehash = $self->{__force_hash_all} || $self->{__force_hash}->{$name};
        my $subclass;
        if ( defined $class ) {
            my $escname = $name;
            $escname =~ s/\W/_/sg;
            $subclass = $class.'::'.$escname;
        }
        if ( $node->{startTag} ) {              # recursive call
            my $child = $self->flat_to_tree( $source, $name, $subclass );
            next unless defined $child;
            my $hasattr = scalar keys %$elem if ref $elem;
            if ( UNIVERSAL::isa( $child, "HASH" ) ) {
                if ( $hasattr ) {
                    # some attributes and some child nodes
                    %$elem = ( %$elem, %$child );
                }
                else {
                    # some child nodes without attributes
                    $elem = $child;
                }
            }
            else {
                if ( $hasattr ) {
                    # some attributes and text node
                    $elem->{$self->{text_node_key}} = $child;
                }
                elsif ( $forcehash ) {
                    # only text node without attributes
                    $elem = { $self->{text_node_key} => $child };
                }
                else {
                    # text node without attributes
                    $elem = $child;
                }
            }
        }
        elsif ( $forcehash && ! ref $elem ) {
            $elem = {};
        }
        # bless to a class by base_class or elem_class
        if ( ref $elem && UNIVERSAL::isa( $elem, "HASH" ) ) {
            if ( defined $subclass ) {
                bless( $elem, $subclass );
            } elsif ( exists $self->{elem_class} && $self->{elem_class} ) {
                my $escname = $name;
                $escname =~ s/\W/_/sg;
                my $elmclass = $self->{elem_class}.'::'.$escname;
                bless( $elem, $elmclass );
            }
        }
        # next unless defined $elem;
        $tree->{$name} ||= [];
        push( @{ $tree->{$name} }, $elem );
    }
    if ( ! $self->{__force_array_all} ) {
        foreach my $key ( keys %$tree ) {
            next if $self->{__force_array}->{$key};
            next if ( 1 < scalar @{ $tree->{$key} } );
            $tree->{$key} = shift @{ $tree->{$key} };
        }
    }
    my $haschild = scalar keys %$tree;
    if ( scalar @$text ) {
        if ( scalar @$text == 1 ) {
            # one text node (normal)
            $text = shift @$text;
        }
        elsif ( ! scalar grep {ref $_} @$text ) {
            # some text node splitted
            $text = join( '', @$text );
        }
        else {
            # some cdata node
            my $join = join( '', map {ref $_ ? $$_ : $_} @$text );
            $text = \$join;
        }
        if ( $haschild ) {
            # some child nodes and also text node
            $tree->{$self->{text_node_key}} = $text;
        }
        else {
            # only text node without child nodes
            $tree = $text;
        }
    }
    elsif ( ! $haschild ) {
        # no child and no text
        $tree = "";
    }
    $tree;
}

sub hash_to_xml {
    my $self      = shift;
    my $name      = shift;
    my $hash      = shift;
    my $out       = [];
    my $attr      = [];
    my $allkeys   = [ keys %$hash ];
    my $fo = $self->{__first_out} if ref $self->{__first_out};
    my $lo = $self->{__last_out}  if ref $self->{__last_out};
    my $firstkeys = [ sort { $fo->{$a} <=> $fo->{$b} } grep { exists $fo->{$_} } @$allkeys ] if ref $fo;
    my $lastkeys  = [ sort { $lo->{$a} <=> $lo->{$b} } grep { exists $lo->{$_} } @$allkeys ] if ref $lo;
    $allkeys = [ grep { ! exists $fo->{$_} } @$allkeys ] if ref $fo;
    $allkeys = [ grep { ! exists $lo->{$_} } @$allkeys ] if ref $lo;
    unless ( exists $self->{use_ixhash} && $self->{use_ixhash} ) {
        $allkeys = [ sort @$allkeys ];
    }
    my $prelen = $self->{__attr_prefix_len};
    my $pregex = $self->{__attr_prefix_rex};

    foreach my $keys ( $firstkeys, $allkeys, $lastkeys ) {
        next unless ref $keys;
        my $elemkey = $prelen ? [ grep { $_ !~ $pregex } @$keys ] : $keys;
        my $attrkey = $prelen ? [ grep { $_ =~ $pregex } @$keys ] : [];

        foreach my $key ( @$elemkey ) {
            my $val = $hash->{$key};
            if ( !defined $val ) {
                push( @$out, "<$key />" );
            }
            elsif ( UNIVERSAL::isa( $val, 'ARRAY' ) ) {
                my $child = $self->array_to_xml( $key, $val );
                push( @$out, $child );
            }
            elsif ( UNIVERSAL::isa( $val, 'SCALAR' ) ) {
                my $child = $self->scalaref_to_cdata( $key, $val );
                push( @$out, $child );
            }
            elsif ( ref $val ) {
                my $child = $self->hash_to_xml( $key, $val );
                push( @$out, $child );
            }
            else {
                my $child = $self->scalar_to_xml( $key, $val );
                push( @$out, $child );
            }
        }

        foreach my $key ( @$attrkey ) {
            my $name = substr( $key, $prelen );
            my $val = &xml_escape( $hash->{$key} );
            push( @$attr, ' ' . $name . '="' . $val . '"' );
        }
    }
    my $jattr = join( '', @$attr );

    if ( defined $name && scalar @$out && ! grep { ! /^</s } @$out ) {
        # Use human-friendly white spacing
        if ( defined $self->{__indent} ) {
            s/^(\s*<)/$self->{__indent}$1/mg foreach @$out;
        }
        unshift( @$out, "\n" );
    }

    my $text = join( '', @$out );
    if ( defined $name ) {
        if ( scalar @$out ) {
            $text = "<$name$jattr>$text</$name>\n";
        }
        else {
            $text = "<$name$jattr />\n";
        }
    }
    $text;
}

sub array_to_xml {
    my $self  = shift;
    my $name  = shift;
    my $array = shift;
    my $out   = [];
    foreach my $val (@$array) {
        if ( !defined $val ) {
            push( @$out, "<$name />\n" );
        }
        elsif ( UNIVERSAL::isa( $val, 'ARRAY' ) ) {
            my $child = $self->array_to_xml( $name, $val );
            push( @$out, $child );
        }
        elsif ( UNIVERSAL::isa( $val, 'SCALAR' ) ) {
            my $child = $self->scalaref_to_cdata( $name, $val );
            push( @$out, $child );
        }
        elsif ( ref $val ) {
            my $child = $self->hash_to_xml( $name, $val );
            push( @$out, $child );
        }
        else {
            my $child = $self->scalar_to_xml( $name, $val );
            push( @$out, $child );
        }
    }

    my $text = join( '', @$out );
    $text;
}

sub scalaref_to_cdata {
    my $self = shift;
    my $name = shift;
    my $ref  = shift;
    my $data = defined $$ref ? $$ref : '';
    $data =~ s#(]])(>)#$1]]><![CDATA[$2#g;
    my $text = '<![CDATA[' . $data . ']]>';
    $text = "<$name>$text</$name>\n" if ( $name ne $self->{text_node_key} );
    $text;
}

sub scalar_to_xml {
    my $self   = shift;
    my $name   = shift;
    my $scalar = shift;
    my $copy   = $scalar;
    my $text   = &xml_escape($copy);
    $text = "<$name>$text</$name>\n" if ( $name ne $self->{text_node_key} );
    $text;
}

sub write_raw_xml {
    my $self = shift;
    my $file = shift;
    my $fh   = Symbol::gensym();
    open( $fh, ">$file" ) or return $self->die( "$! - $file" );
    print $fh @_;
    close($fh);
}

sub read_raw_xml {
    my $self = shift;
    my $file = shift;
    my $fh   = Symbol::gensym();
    open( $fh, $file ) or return $self->die( "$! - $file" );
    local $/ = undef;
    my $text = <$fh>;
    close($fh);
    $text;
}

sub xml_decl_encoding {
    my $textref = shift;
    return unless defined $$textref;
    my $args    = ( $$textref =~ /^(?:\s*\xEF\xBB\xBF)?\s*<\?xml(\s+\S.*)\?>/s )[0] or return;
    my $getcode = ( $args =~ /\s+encoding=(".*?"|'.*?')/ )[0] or return;
    $getcode =~ s/^['"]//;
    $getcode =~ s/['"]$//;
    $getcode;
}

sub encode_from_to {
    my $self   = shift;
    my $txtref = shift or return;
    my $from   = shift or return;
    my $to     = shift or return;

    unless ( defined $Encode::EUCJPMS::VERSION ) {
        $from = 'EUC-JP' if ( $from =~ /\beuc-?jp-?(win|ms)$/i );
        $to   = 'EUC-JP' if ( $to   =~ /\beuc-?jp-?(win|ms)$/i );
    }

    if ( $from =~ /^utf-?8$/i ) {
        $$txtref =~ s/^\xEF\xBB\xBF//s;         # UTF-8 BOM (Byte Order Mark)
    }

    my $setflag = $self->{utf8_flag} if exists $self->{utf8_flag};
    if ( $] < 5.008001 && $setflag ) {
        return $self->die( "Perl 5.8.1 is required for utf8_flag: $]" );
    }

    if ( $] >= 5.008 ) {
        &load_encode();
        my $check = ( $Encode::VERSION < 2.13 ) ? 0x400 : Encode::FB_XMLCREF();
        if ( $] >= 5.008001 && utf8::is_utf8( $$txtref ) ) {
            if ( $to =~ /^utf-?8$/i ) {
                # skip
            } else {
                $$txtref = Encode::encode( $to, $$txtref, $check );
            }
        } else {
            $$txtref = Encode::decode( $from, $$txtref );
            if ( $to =~ /^utf-?8$/i && $setflag ) {
                # skip
            } else {
                $$txtref = Encode::encode( $to, $$txtref, $check );
            }
        }
    }
    elsif ( (  uc($from) eq 'ISO-8859-1'
            || uc($from) eq 'US-ASCII'
            || uc($from) eq 'LATIN-1' ) && uc($to) eq 'UTF-8' ) {
        &latin1_to_utf8($txtref);
    }
    else {
        my $jfrom = &get_jcode_name($from);
        my $jto   = &get_jcode_name($to);
        return $to if ( uc($jfrom) eq uc($jto) );
        if ( $jfrom && $jto ) {
            &load_jcode();
            if ( defined $Jcode::VERSION ) {
                Jcode::convert( $txtref, $jto, $jfrom );
            }
            else {
                return $self->die( "Jcode.pm is required: $from to $to" );
            }
        }
        else {
            return $self->die( "Encode.pm is required: $from to $to" );
        }
    }
    $to;
}

sub load_jcode {
    return if defined $Jcode::VERSION;
    local $@;
    eval { require Jcode; };
}

sub load_encode {
    return if defined $Encode::VERSION;
    local $@;
    eval { require Encode; };
}

sub latin1_to_utf8 {
    my $strref = shift;
    $$strref =~ s{
        ([\x80-\xFF])
    }{
        pack( 'C2' => 0xC0|(ord($1)>>6),0x80|(ord($1)&0x3F) )
    }exg;
}

sub get_jcode_name {
    my $src = shift;
    my $dst;
    if ( $src =~ /^utf-?8$/i ) {
        $dst = 'utf8';
    }
    elsif ( $src =~ /^euc.*jp(-?(win|ms))?$/i ) {
        $dst = 'euc';
    }
    elsif ( $src =~ /^(shift.*jis|cp932|windows-31j)$/i ) {
        $dst = 'sjis';
    }
    elsif ( $src =~ /^iso-2022-jp/ ) {
        $dst = 'jis';
    }
    $dst;
}

sub xml_escape {
    my $str = shift;
    return '' unless defined $str;
    # except for TAB(\x09),CR(\x0D),LF(\x0A)
    $str =~ s{
        ([\x00-\x08\x0B\x0C\x0E-\x1F\x7F])
    }{
        sprintf( '&#%d;', ord($1) );
    }gex;
    $str =~ s/&(?!#(\d+;|x[\dA-Fa-f]+;))/&amp;/g;
    $str =~ s/</&lt;/g;
    $str =~ s/>/&gt;/g;
    $str =~ s/'/&apos;/g;
    $str =~ s/"/&quot;/g;
    $str;
}

sub xml_unescape {
    my $str = shift;
    my $map = {qw( quot " lt < gt > apos ' amp & )};
    $str =~ s{
        (&(?:\#(\d+)|\#x([0-9a-fA-F]+)|(quot|lt|gt|apos|amp));)
    }{
        $4 ? $map->{$4} : &char_deref($1,$2,$3);
    }gex;
    $str;
}

sub char_deref {
    my( $str, $dec, $hex ) = @_;
    if ( defined $dec ) {
        return &code_to_utf8( $dec ) if ( $dec < 256 );
    }
    elsif ( defined $hex ) {
        my $num = hex($hex);
        return &code_to_utf8( $num ) if ( $num < 256 );
    }
    return $str;
}

sub code_to_utf8 {
    my $code = shift;
    if ( $code < 128 ) {
        return pack( C => $code );
    }
    elsif ( $code < 256 ) {
        return pack( C2 => 0xC0|($code>>6), 0x80|($code&0x3F));
    }
    elsif ( $code < 65536 ) {
        return pack( C3 => 0xC0|($code>>12), 0x80|(($code>>6)&0x3F), 0x80|($code&0x3F));
    }
    return shift if scalar @_;      # default value
    sprintf( '&#x%04X;', $code );
}

# ====================
# | SUPPORT CODE END |
# ====================
