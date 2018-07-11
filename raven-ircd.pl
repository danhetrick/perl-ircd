#!/usr/bin/perl
#   _____                         _____ _____   _____    _ 
#  |  __ \                       |_   _|  __ \ / ____|  | |
#  | |__) |__ ___   _____ _ __     | | | |__) | |     __| |
#  |  _  // _` \ \ / / _ \ '_ \    | | |  _  /| |    / _` |
#  | | \ \ (_| |\ V /  __/ | | |  _| |_| | \ \| |___| (_| |
#  |_|  \_\__,_| \_/ \___|_| |_| |_____|_|  \_\\_____\__,_|
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

# =================
# | MODULES BEGIN |
# =================

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# { STANDARD LIBRARY MODULES }
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# strict -- Perl pragma to restrict unsafe constructs
use strict;

# warnings -- Perl pragma to warn users of problematic code
use warnings;

# FindBin -- Locates directory of original perl script
use FindBin qw($RealBin);

# File::Spec -- Portably perform operations on file names
use File::Spec;

# lib -- Manipulate @INC at compile time
# Looks for additional modules in /lib, in the same directory
# as the script. Done in a platform agnostic fashion, so environments
# with different ways of notating directory paths are handled correctly.
use lib File::Spec->catfile($RealBin,'lib');

# ~~~~~~~~~~~~~~~~
# { CPAN MODULES }
# ~~~~~~~~~~~~~~~~

# Perl Object Environment
# From the official website, https://poe.perl.org: "POE is a Perl
# framework for reactive systems, cooperative multitasking, and
# network applications."
use POE;

# ~~~~~~~~~~~~~~~~~
# { LOCAL MODULES }
# ~~~~~~~~~~~~~~~~~

# XML::TreePP -- Pure Perl implementation for parsing/writing XML documents
# By Yusuke Kawasaki
use XML::TreePP;

# RavenIRCd -- IRC server functionality
# Inherits from POE::Component::Server::IRC
use RavenIRCd;

# ===============
# | MODULES END |
# ===============

# =================
# | GLOBALS BEGIN |
# =================

# -------------
# | CONSTANTS |
# -------------

# ~~~~~~~~~~~~~~~~~~~~~~~
# { AUTH LIST STRUCTURE }
# ~~~~~~~~~~~~~~~~~~~~~~~
use constant AUTH_MASK			=> 0;
use constant AUTH_PASSWORD		=> 1;
use constant AUTH_SPOOF			=> 2;
use constant AUTH_TILDE			=> 3;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~
# { OPERATOR LIST STRUCTURE }
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~
use constant OPERATOR_USERNAME	=> 0;
use constant OPERATOR_PASSWORD	=> 1;
use constant OPERATOR_IPMASK	=> 2;

# -----------
# | SCALARS |
# -----------

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# { CONFIGURATION FILE SETTINGS }
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Default config filename.
my $CONFIGURATION_FILE				= "ircd.xml";
# Where the server will look for config files besides the local directory.
my $CONFIGURATION_DIRECTORY_NAME	= "config";

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# { APPLICATION DATA SETTINGS }
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# These are used by generate_banner(), and nowhere else.
my $APPLICATION_NAME = "Raven IRCd";
my $VERSION		= "0.021";
my $APPLICATION_DESCRIPTION = "An IRC server written in Perl and POE";
my $APPLICATION_URL = "https://github.com/danhetrick/raven-ircd";

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~
# { SERVER DEFAULT SETTINGS }
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~
# These are the settings the server will use if no other
# setting is supplied by a configuration file.
my $SERVER_NAME		= "raven.irc.server";
my $NICKNAME_LENGTH	= 15;
my $SERVER_NETWORK	= "RavenNet";
my $MAX_TARGETS		= 4;
my $MAX_CHANNELS	= 15;
my $SERVER_INFO		= $APPLICATION_DESCRIPTION;
my $DEFAULT_PORT	= 6667;
my $DEFAULT_AUTH	= '*@*';
my $VERBOSE			= 1;

# ----------
# | ARRAYS |
# ----------

# These arrays are used in _start() to set the listening ports, 
# the list of authorized connections, and the list of operator accounts
# the server will use. They are populated by the data supplied in
# configuration files, loaded into memory by load_xml_configuration_file().
# @LISTENER_PORTS is an array of scalars, each containing a port number.
# @AUTHS is an array of arrays, each mapped using AUTH LIST STRUCTURE
# set in the CONSTANTS. @OPERATORS is an array of arrays, each mapped using
# OPERATOR LIST STRUCTURE set in the CONSTANTS.
my @LISTENER_PORTS	= ();	# List of server listening ports to use
my @AUTHS			= ();	# List of auth entries
my @OPERATORS		= ();	# List of operator entries

# ===============
# | GLOBALS END |
# ===============

# ======================
# | MAIN PROGRAM BEGIN |
# ======================

# See if a config file is passed to the program in an argument.
if($#ARGV>=0){ $CONFIGURATION_FILE=$ARGV[0]; }

# Look for the configuration file in the local directory or the config/ directory.
my $found_configuration_file = find_configuration_file($CONFIGURATION_FILE);

# If configuration file is found, load it. If the configure file is *not* found,
# use default settings and warn the user.  No matter what, print the banner to
# the console if verbosity is turned on.
if($found_configuration_file){
	# Configuration file found, load it into memory.
	load_xml_configuration_file($found_configuration_file);
	# Display our banner if verbosity is turned on.
	if($VERBOSE==1){
		print generate_banner();
	}
	# Let the user know what configuration file was loaded.
	verbose("Loaded configuration file '$found_configuration_file'");
} else {
	# Display our banner if verbosity is turned on.
	if($VERBOSE==1){
			print generate_banner();
	}
	# Configuration file *not* found; defaults will be used.
	# Warn the user that no file was found.
	display_warning("No configuration file found; starting server with default settings");
}

# Set up our server configuration.
my %config = (
    servername	=> $SERVER_NAME, 
    nicklen		=> $NICKNAME_LENGTH,
    network		=> $SERVER_NETWORK,
    maxtargets	=> $MAX_TARGETS,
    maxchannels	=> $MAX_CHANNELS,
    info		=> $SERVER_INFO
);

# Spawn our RavenIRCd instance, and pass it our server configuration.
my $pocosi = RavenIRCd->spawn( config => \%config );

# Create our POE session, and hook in the _start() handler.
# _start() will be executed when the POE kernel is started up.
POE::Session->create(
    package_states => [
        'main' => [qw(_start)],
    ],
    heap => { ircd => $pocosi },
);

# Start the server!
$poe_kernel->run();

# ====================
# | MAIN PROGRAM END |
# ====================

# =============================
# | SUPPORT SUBROUTINES BEGIN |
# =============================

# ----------------------
# | POE Event Handlers |
# ----------------------

#	_start()

# --------------------
# | User Interaction |
# --------------------

#	timestamp()
#	verbose()
#	generate_banner()
#	logo()
#	display_error_and_exit()
#	display_warning()

# -------------------------------
# | Configuration File Handling |
# -------------------------------

#	find_configuration_file()
#	load_xml_configuration_file()

# ----------------------
# | POE Event Handlers |
# ----------------------

# _start()
# Arguments: See description
# Returns:  Nothing
# Description:  This subroutine is called as soon as the RavenIRCd object is ran
#               after creation; it is not called directly in the program.
#               Here's where auth, port, and operator data is loaded into the
#               server; if those settings are "missing" (due to a lack of a configuration
#               file, for example), the default settings are applied. Default auth
#               setting is *@* (allowing any user on any host to connect). Default
#               port setting is 6667 (the "standard" IRC port). Default operators
#               are non-existant, so no operator accounts are loaded into the server.
#               @AUTHS, @LISTENER_PORTS, and @OPERATORS are populated by
#               load_xml_configuration_file() with data supplied in the configuration
#               files.
sub _start {
    my ($kernel, $heap) = @_[KERNEL, HEAP];
 
 	# Make sure we get all events
    $heap->{ircd}->yield('register', 'all');

    # Add authorized connections
    if(scalar @AUTHS >=1){
    	# Add authorized connections from the list in @AUTHS
	    foreach my $a (@AUTHS){
	    	my @entry = @{$a};
	    	$heap->{ircd}->add_auth(
		        mask		=> $entry[AUTH_MASK],
		        password	=> $entry[AUTH_PASSWORD],
		        spoof		=> $entry[AUTH_SPOOF],
		        no_tilde	=> $entry[AUTH_TILDE],
    		); 
    	}
    } else {
    		# @AUTHS is empty, so let the user know and use the default auth entry.
    		display_warning("Auth element not found. Using $DEFAULT_AUTH as the auth");
    		$heap->{ircd}->add_auth(
	        	mask		=> $DEFAULT_AUTH,
    		); 
    }
 
    # Add listening port(s)
    if(scalar @LISTENER_PORTS >=1){
    	# Add ports from the list in @LISTENER_PORTS
	    foreach my $p (@LISTENER_PORTS){
	    	$heap->{ircd}->add_listener(port => $p);
	    }
	} else {
		# @LISTENER_PORTS is empty, so let the user know and use the default port.
		$heap->{ircd}->add_listener(port => $DEFAULT_PORT);
		display_warning("Port element not found. Using $DEFAULT_PORT as the listening port");
	}
 
    # Add IRC operators
    if(scalar @OPERATORS>=1){
    	# Add operators from the list in @OPERATORS
	    foreach my $o (@OPERATORS){
			my @entry = @{$o};
			$heap->{ircd}->add_operator(
		        {
		            username	=> $entry[OPERATOR_USERNAME],
		            password	=> $entry[OPERATOR_PASSWORD],
		            ipmask		=> $entry[OPERATOR_IPMASK],
		        }
		    );
		}
	} else {
		# @OPERATORS is empty, so let the user know and start with no operators.
		display_warning('Operator element not found. Server will start without operators');
	}
}

# --------------------
# | User Interaction |
# --------------------

# timestamp()
# Arguments: None
# Returns:  Scalar (timestamp)
# Description:  Generates a timestamp for the current time/date,
#               and returns it. This subroutine is used to generate the
#               timestamps for display_warning() and verbose().
sub timestamp {
	my ($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = gmtime();
	my $year = 1900 + $yearOffset;
	return "[$hour:$minute:$second $month/$dayOfMonth/$year]";
}

# verbose()
# Arguments: 1 (scalar, text to print)
# Returns: Nothing
# Description: Prints timestamped text to the console if verbosity is turned on.
 sub verbose {
	my $txt = shift;
	my $time = timestamp();
	if($VERBOSE==1){
		print "$time $txt\n";
	}
}

# generate_banner()
# Arguments: None
# Returns: Scalar
# Description: Generates a banner with the logo and application information, and returns it.
#              App name, version, description, and URL text length is measured so that the
#              banner will look all neat and spiffy, even if we make changes to the text.
#              Can be turned on or off with the config->banner element.
#              Looks like this:
#  _____                         _____ _____   _____    _
# |  __ \                       |_   _|  __ \ / ____|  | |
# | |__) |__ ___   _____ _ __     | | | |__) | |     __| |
# |  _  // _` \ \ / / _ \ '_ \    | | |  _  /| |    / _` |
# | | \ \ (_| |\ V /  __/ | | |  _| |_| | \ \| |___| (_| |
# |_|  \_\__,_| \_/ \___|_| |_| |_____|_|  \_\\_____\__,_|
# ----------------------------------------Raven IRCd 0.021
# -------------------An IRC server written in Perl and POE
# ----------------https://github.com/danhetrick/raven-ircd
sub generate_banner {
	my $BANNER_PADDING = "-";	# What the spaces to the left of the text is filled with
	my $LOGO_WIDTH	= 56;		# The width (give or take) of the text banner generated with logo()

	my $b = logo().($BANNER_PADDING x ($LOGO_WIDTH - length("$APPLICATION_NAME $VERSION")))."$APPLICATION_NAME $VERSION\n";
	$b .= $BANNER_PADDING x ($LOGO_WIDTH - length("$APPLICATION_DESCRIPTION"))."$APPLICATION_DESCRIPTION\n";
	$b .= $BANNER_PADDING x ($LOGO_WIDTH - length("$APPLICATION_URL"))."$APPLICATION_URL\n\n";
	return $b;
}

# logo()
# Arguments: None
# Returns: Scalar
# Description: Returns the text logo for Raven IRCd. This is only
#              used for the startup banner.
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
	print "ERROR: $msg\n";
	exit 1;
}

# display_warning()
# Arguments: 1 (scalar, warning text)
# Returns: Nothing
# Description: Displays a timestamped warning to the user; only displayed
#              if verbosity is turned on.
sub display_warning {
	my $msg = shift;
	my $time = timestamp();
	if($VERBOSE==1){
		print "$time WARNING: $msg\n";
	}
}

# -------------------------------
# | Configuration File Handling |
# -------------------------------

# find_configuration_file()
# Arguments: 1 (scalar, filename)
# Returns: Scalar (filename)
# Description: Looks for a given configuration file in the several directories.
#              This subroutine was written with cross-platform compatability in
#              mind; in theory, this should work on any platform that can run
#              Perl (so, OSX, *NIX, Linux, Windows, etc). Not "expensive" to
#              run, as it doesn't do directory searches.
sub find_configuration_file {
	my $filename = shift;

	# If the filename is found, return it
	if((-e $filename)&&(-f $filename)){ return $filename; }

	# Look for the file in $RealBin/filename
	my $f = File::Spec->catfile($RealBin,$filename);
	if((-e $f)&&(-f $f)){ return $f; }

	# Look for the file in $CONFIGURATION_DIRECTORY_NAME/filename
	$f = File::Spec->catfile($CONFIGURATION_DIRECTORY_NAME,$filename);
	if((-e $f)&&(-f $f)){ return $f; }

	# Look for the file in $Realbin/$CONFIGURATION_DIRECTORY_NAME/filename
	$f = File::Spec->catfile($RealBin,$CONFIGURATION_DIRECTORY_NAME,$filename);
	if((-e $f)&&(-f $f)){ return $f; }

	return undef;
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

	# Double check for file existence. If the file is not found, alert the
	# user and exit. This is already checked before this subroutine is normally
	# called, but it doesn't hurt to check again.
	$filename = find_configuration_file($filename);
	if(!$filename){
		display_error_and_exit("Configuration file '$filename' not found");
	}

	# ------------------
	# | IMPORT ELEMENT |
	# ------------------
	# <import>filename</import>
	#
	# Allows importing of config files.
	if(ref($tree->{import}) eq 'ARRAY'){
		foreach my $i (@{$tree->{import}}) {
			# Multiple import elements
			$i = find_configuration_file($i);
			if(!$i){
				# Imported file not found; alert user and exit
				display_error_and_exit("Configuration file '$filename' not found");
			}
			# Recursively call load_xml_configuration_file() to load in the settings
			# from the imported file
			load_xml_configuration_file($i);
		}
	} elsif($tree->{import}){
		# Single import element
		my $f = find_configuration_file($tree->{import});
		if(!$f){
			# Imported file not found; alert user and exit
			display_error_and_exit("Configuration file '$filename' not found");
		}
		# Recursively call load_xml_configuration_file() to load in the settings
		# from the imported file
		load_xml_configuration_file($f);
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
	# Adds an operator to the IRC server.  Ipmask is optional.
	if(ref($tree->{operator}) eq 'ARRAY'){
		foreach my $a (@{$tree->{operator}}) {
			# Multiple operator elements
			my @op = ();

			# operator->username
			if(ref($a->{username}) eq 'ARRAY'){
				display_error_and_exit("Error in $filename: operator element can't have more than one username element");
			}
			if($a->{username}){
				push(@op,$a->{username});
			} else {
				display_error_and_exit("Error in $filename: operator element missing a username element");
			}

			# operator->password
			if(ref($a->{password}) eq 'ARRAY'){
				display_error_and_exit("Error in $filename: operator element can't have more than one password element");
			}
			if($a->{password}){
				push(@op,$a->{password});
			} else {
				display_error_and_exit("Error in $filename: operator element missing a password element");
			}
			
			# operator->ipmask
			if(ref($a->{ipmask}) eq 'ARRAY'){
				display_error_and_exit("Error in $filename: operator element can't have more than one ipmask element");
			}
			if($a->{ipmask}){
				push(@op,$a->{ipmask});
			} else {
				push(@op,undef);
			}

			# Add operator entry to the operator list
			push(@OPERATORS,\@op);
		}
	} elsif($tree->{operator}){
		# Single operator element
		my @op = ();

		# operator->username
		if($tree->{operator}->{username}){
			if(ref($tree->{operator}->{username}) eq 'ARRAY'){
				display_error_and_exit("Error in $filename: operator element can't have more than one username element");
			}
			push (@op,$tree->{operator}->{username});
		} else {
			display_error_and_exit("Error in $filename: operator element missing a username element");
		}

		# operator->password
		if($tree->{operator}->{password}){
			if(ref($tree->{operator}->{password}) eq 'ARRAY'){
				display_error_and_exit("Error in $filename: operator element can't have more than one password element");
			}
			push(@op,$tree->{operator}->{password});
		} else {
			display_error_and_exit("Error in $filename: operator element missing a password element");
		}

		# operator->ipmask
		if($tree->{operator}->{ipmask}){
			if(ref($tree->{operator}->{ipmask}) eq 'ARRAY'){
				display_error_and_exit("Error in $filename: operator element can't have more than one ipmask element");
			}
			push(@op,$tree->{operator}->{ipmask});
		} else {
			push(@op,undef);
		}

		# Add operator entry to the operator list
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
			# Multiple auth elements
			my @auth = ();

			# auth->mask
			if(ref($a->{mask}) eq 'ARRAY'){
				display_error_and_exit("Error in $filename: auth element can't have more than one mask element");
			}
			if($a->{mask}){
				push(@auth,$a->{mask});
			} else {
				display_error_and_exit("Error in $filename: auth element missing a mask element");
			}

			# auth->password
			if(ref($a->{password}) eq 'ARRAY'){
				display_error_and_exit("Error in $filename: auth element can't have more than one password element");
			}
			if($a->{password}){
				push(@auth,$a->{password});
			} else {
				push(@auth,undef);
			}

			# auth->spoof
			if(ref($a->{spoof}) eq 'ARRAY'){
				display_error_and_exit("Error in $filename: auth element can't have more than one spoof element");
			}
			if($a->{spoof}){
				push(@auth,$a->{spoof});
			} else {
				push(@auth,undef);
			}

			# auth->no_tilde
			if(ref($a->{no_tilde}) eq 'ARRAY'){
				display_error_and_exit("Error in $filename: auth element can't have more than one no_tilde element");
			}
			if($a->{no_tilde}){
				push(@auth,$a->{no_tilde});
			} else {
				push(@auth,undef);
			}

			# Add auth entry to the auth list
			push(@AUTHS,\@auth);
		}
	} elsif($tree->{auth}){
		# Single auth element
		my @auth = ();

		# auth->mask
		if(ref($tree->{auth}->{mask}) eq 'ARRAY'){
			display_error_and_exit("Error in $filename: auth element can't have more than one mask element");
		}
		if($tree->{auth}->{mask}){
			push (@auth,$tree->{auth}->{mask});
		} else {
			display_error_and_exit("Error in $filename: auth element missing a mask element");
		}

		# auth->password
		if(ref($tree->{auth}->{password}) eq 'ARRAY'){
			display_error_and_exit("Error in $filename: auth element can't have more than one password element");
		}
		if($tree->{auth}->{password}){
			push(@auth,$tree->{auth}->{password});
		} else {
			push(@auth,undef);
		}

		# auth->spoof
		if(ref($tree->{auth}->{spoof}) eq 'ARRAY'){
			display_error_and_exit("Error in $filename: auth element can't have more than one spoof element");
		}
		if($tree->{auth}->{spoof}){
			push(@auth,$tree->{auth}->{spoof});
		} else {
			push(@auth,undef);
		}

		# auth->no_tilde
		if(ref($tree->{auth}->{no_tilde}) eq 'ARRAY'){
			display_error_and_exit("Error in $filename: auth element can't have more than one no_tilde element");
		}
		if($tree->{auth}->{no_tilde}){
			push(@auth,$tree->{auth}->{no_tilde});
		} else {
			push(@auth,undef);
		}

		# Add auth entry to the auth list
		push(@AUTHS,\@auth);
	}

	# ------------------
	# | CONFIG ELEMENT |
	# ------------------
	# <config>
	# 	<verbose>1</verbose>
	# 	<port>6667</port>
	# 	<name>raven.irc.server</name>
	# 	<nicklength>15</nicklength>
	# 	<network>RavenNet</network>
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

# ===========================
# | SUPPORT SUBROUTINES END |
# ===========================
