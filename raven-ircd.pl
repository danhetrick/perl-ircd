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
my $CONFIGURATION_FILE				= "default.xml";
# Where the server will look for config files besides the local directory.
my $CONFIGURATION_DIRECTORY_NAME	= "settings";

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# { APPLICATION DATA SETTINGS }
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# These are used by generate_banner(), and nowhere else.
my $APPLICATION_NAME		= "Raven IRCd";
my $VERSION					= "0.025";
my $APPLICATION_DESCRIPTION	= "Raven IRCd is an IRC server written in Perl and POE";
my $APPLICATION_URL			= "https://github.com/danhetrick/raven-ircd";

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~
# { SERVER DEFAULT SETTINGS }
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~
# These are the settings the server will use if no other
# setting is supplied by a configuration file.
my $SERVER_NAME				= "raven.irc.server";
my $NICKNAME_LENGTH			= 15;
my $SERVER_NETWORK			= "RavenNet";
my $MAX_TARGETS				= 4;
my $MAX_CHANNELS			= 15;
my $SERVER_INFO				= $APPLICATION_DESCRIPTION;
my $DEFAULT_PORT			= 6667;
my $DEFAULT_AUTH			= '*@*';
my $VERBOSE					= 1;
my $BANNER					= 1;
my $WARNING					= 1;
my $DEFAULT_ADMIN_LINE_1	= "$APPLICATION_NAME $VERSION";
my $DEFAULT_ADMIN_LINE_2	= "The operator of this server didn't set up the admin option.";
my $DEFAULT_ADMIN_LINE_3	= "Sorry!";
my $DESCRIPTION				= "$APPLICATION_NAME $VERSION";

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
# @IMPORTED_FILES contains a list of all the files imported by configuration
# files, so we can display them to the user with verbose() after we've
# loaded them.
# @ADMIN contains the three lines returned by the IRC command /admin.
# It's also populated by load_xml_configuration_file(), and then sanity
# checked by check_admin_info(), which makes sure that the array only
# contains 3 items and sets them to default values if they are missing.
my @LISTENER_PORTS	= ();	# List of server listening ports to use
my @AUTHS			= ();	# List of auth entries
my @OPERATORS		= ();	# List of operator entries
my @IMPORTED_FILES	= ();	# List of imported files
my @ADMIN			= ();	# Text returned by the /admin command

# ===============
# | GLOBALS END |
# ===============

# ======================
# | MAIN PROGRAM BEGIN |
# ======================

if((scalar @ARGV>=1)&&(lc($ARGV[0]) eq 'default')){
	# Display banner unless configured otherwise
	if($BANNER==1){ print generate_banner(); }
	# User wants to start with all default settings, no configuration
	# files, so we won't even bother trying to look for or load any.
	display_warning("Starting server with default settings");
} else {
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
		# Display banner unless configured otherwise
		if($BANNER==1){ print generate_banner(); }
		# Let the user know what configuration file was loaded.
		verbose("Loaded configuration file '$found_configuration_file'");
	} else {
		# Display banner unless configured otherwise
		if($BANNER==1){ print generate_banner(); }
		# Configuration file *not* found; defaults will be used.
		# Warn the user that no file was found.
		display_warning("Configuration file '$CONFIGURATION_FILE' not found!");
		display_warning("Starting server with default settings");
	}
	# Display any files imported by any configuration files
	if(scalar @IMPORTED_FILES>=1){
		foreach my $i (@IMPORTED_FILES){
			verbose("Loaded configuration file '$i'");
		}
	}

	# Do a sanity check for the config->admin element
	# No more than three entries are allowed, so make sure that
	# @ADMIN (the array that contains the entries) has no more
	# or no less than 3 entries. Since it's not really a critical
	# setting, we'll only warn the user if there's too many, rather
	# than error and exit, and we'll only use the first three
	# entries.
	check_admin_info();
}

# Set up our server configuration.
my %config = (
    servername	=> $SERVER_NAME, 
    nicklen		=> $NICKNAME_LENGTH,
    network		=> $SERVER_NETWORK,
    maxtargets	=> $MAX_TARGETS,
    maxchannels	=> $MAX_CHANNELS,
    info		=> $SERVER_INFO,
    admin		=> \@ADMIN,
    serverdesc	=> $DESCRIPTION,
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

#	check_admin_info()
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
	    	verbose("Adding auth entry for '$entry[AUTH_MASK]'");
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
	    	verbose("Adding a listener on port '$p'");
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
    	verbose("Adding operator(s)");
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
# ----------------------------------------Raven IRCd 0.025
# ------Raven IRCd is an IRC server written in Perl and POE
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
#              if verbosity is turned on. Warnings will *always* display
#              if warnings are turned on, even if verbosity is turned off.
sub display_warning {
	my $msg = shift;
	my $time = timestamp();
	if($VERBOSE==1){
		print "$time WARNING: $msg\n";
	}
	if(($VERBOSE==0)&&($WARNING==1)){
		print "$time WARNING: $msg\n";
	}
}

# -------------------------------
# | Configuration File Handling |
# -------------------------------

# check_admin_info()
# Arguments: 0
# Returns: Nothing
# Description: Makes sure that the @ADMIN array is populated correctly; it should
#              have no more (or no less) than three entries. This is used to set
#              up the /admin IRC command, and the text that's returned by that
#              command is what's in the array. If only one or two lines are set
#              in the configuration files, the rest of the array is populated with
#              blank entries. If the array isn't populated at *all*, the default
#              server values are entered (which are in the scalars $DEFAULT_ADMIN_LINE_1,
#              $DEFAULT_ADMIN_LINE_2, and $DEFAULT_ADMIN_LINE_3).
sub check_admin_info {
	if(scalar @ADMIN==3) { return; }
	if(scalar @ADMIN>3){
		display_warning("Too many admin elements set; using only the first three");
		my @ac;
		push(@ac,shift @ADMIN);
		push(@ac,shift @ADMIN);
		push(@ac,shift @ADMIN);
		@ADMIN = @ac;
		return;
	}
	if(scalar @ADMIN==2){
		push(@ADMIN,"");
		return;
	}
	if(scalar @ADMIN==1){
		push(@ADMIN,"");
		push(@ADMIN,"");
		return;
	}
	if(scalar @ADMIN==0){
		push(@ADMIN,$DEFAULT_ADMIN_LINE_1);
		push(@ADMIN,$DEFAULT_ADMIN_LINE_2);
		push(@ADMIN,$DEFAULT_ADMIN_LINE_3);
		return;
	}
}

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

	# If the parsed tree is empty, there's nothing to parse; exit subroutine
	# This may occur because all the elements in the configuration file are
	# commented out.
	if($tree eq '') { return; }

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
			# Add imported file to the imported file list
			push(@IMPORTED_FILES,$i);
		}
	} elsif($tree->{import} ne undef){
		# Single import element
		my $f = find_configuration_file($tree->{import});
		if(!$f){
			# Imported file not found; alert user and exit
			display_error_and_exit("Configuration file '$filename' not found");
		}
		# Recursively call load_xml_configuration_file() to load in the settings
		# from the imported file
		load_xml_configuration_file($f);
		# Add imported file to the imported file list
		push(@IMPORTED_FILES,$f);
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
			if($a->{username} ne undef){
				push(@op,$a->{username});
			} else {
				display_error_and_exit("Error in $filename: operator element missing a username element");
			}

			# operator->password
			if(ref($a->{password}) eq 'ARRAY'){
				display_error_and_exit("Error in $filename: operator element can't have more than one password element");
			}
			if($a->{password} ne undef){
				push(@op,$a->{password});
			} else {
				display_error_and_exit("Error in $filename: operator element missing a password element");
			}
			
			# operator->ipmask
			if(ref($a->{ipmask}) eq 'ARRAY'){
				display_error_and_exit("Error in $filename: operator element can't have more than one ipmask element");
			}
			if($a->{ipmask} ne undef){
				push(@op,$a->{ipmask});
			} else {
				push(@op,undef);
			}

			# Add operator entry to the operator list
			push(@OPERATORS,\@op);
		}
	} elsif($tree->{operator} ne undef){
		# Single operator element
		my @op = ();

		# operator->username
		if($tree->{operator}->{username} ne undef){
			if(ref($tree->{operator}->{username}) eq 'ARRAY'){
				display_error_and_exit("Error in $filename: operator element can't have more than one username element");
			}
			push (@op,$tree->{operator}->{username});
		} else {
			display_error_and_exit("Error in $filename: operator element missing a username element");
		}

		# operator->password
		if($tree->{operator}->{password} ne undef){
			if(ref($tree->{operator}->{password}) eq 'ARRAY'){
				display_error_and_exit("Error in $filename: operator element can't have more than one password element");
			}
			push(@op,$tree->{operator}->{password});
		} else {
			display_error_and_exit("Error in $filename: operator element missing a password element");
		}

		# operator->ipmask
		if($tree->{operator}->{ipmask} ne undef){
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
			if($a->{mask} ne undef){
				push(@auth,$a->{mask});
			} else {
				display_error_and_exit("Error in $filename: auth element missing a mask element");
			}

			# auth->password
			if(ref($a->{password}) eq 'ARRAY'){
				display_error_and_exit("Error in $filename: auth element can't have more than one password element");
			}
			if($a->{password} ne undef){
				push(@auth,$a->{password});
			} else {
				push(@auth,undef);
			}

			# auth->spoof
			if(ref($a->{spoof}) eq 'ARRAY'){
				display_error_and_exit("Error in $filename: auth element can't have more than one spoof element");
			}
			if($a->{spoof} ne undef){
				push(@auth,$a->{spoof});
			} else {
				push(@auth,undef);
			}

			# auth->no_tilde
			if(ref($a->{no_tilde}) eq 'ARRAY'){
				display_error_and_exit("Error in $filename: auth element can't have more than one no_tilde element");
			}
			if($a->{no_tilde} ne undef){
				push(@auth,$a->{no_tilde});
			} else {
				push(@auth,undef);
			}

			# Add auth entry to the auth list
			push(@AUTHS,\@auth);
		}
	} elsif($tree->{auth} ne undef){
		# Single auth element
		my @auth = ();

		# auth->mask
		if(ref($tree->{auth}->{mask}) eq 'ARRAY'){
			display_error_and_exit("Error in $filename: auth element can't have more than one mask element");
		}
		if($tree->{auth}->{mask} ne undef){
			push (@auth,$tree->{auth}->{mask});
		} else {
			display_error_and_exit("Error in $filename: auth element missing a mask element");
		}

		# auth->password
		if(ref($tree->{auth}->{password}) eq 'ARRAY'){
			display_error_and_exit("Error in $filename: auth element can't have more than one password element");
		}
		if($tree->{auth}->{password} ne undef){
			push(@auth,$tree->{auth}->{password});
		} else {
			push(@auth,undef);
		}

		# auth->spoof
		if(ref($tree->{auth}->{spoof}) eq 'ARRAY'){
			display_error_and_exit("Error in $filename: auth element can't have more than one spoof element");
		}
		if($tree->{auth}->{spoof} ne undef){
			push(@auth,$tree->{auth}->{spoof});
		} else {
			push(@auth,undef);
		}

		# auth->no_tilde
		if(ref($tree->{auth}->{no_tilde}) eq 'ARRAY'){
			display_error_and_exit("Error in $filename: auth element can't have more than one no_tilde element");
		}
		if($tree->{auth}->{no_tilde} ne undef){
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
	#	<banner>1</banner>
	#	<warning>1</warning>
	# </config>
	#
	# Allows for server configuration.  Multiple port elements are allowed. All elements are optional;
	# default settings will be used for all missing elements.

	# config->verbose element
	if(ref($tree->{config}->{verbose}) eq 'ARRAY'){
		display_error_and_exit("Error in $filename: config element can't have more than one verbose element");
	} elsif($tree->{config}->{verbose} ne undef){
		$VERBOSE = $tree->{config}->{verbose};
	}

	# config->port element
	if(ref($tree->{config}->{port}) eq 'ARRAY'){
		foreach my $p (@{$tree->{config}->{port}}) {
			push(@LISTENER_PORTS,$p);
		}
	} elsif($tree->{config}->{port} ne undef){
		push(@LISTENER_PORTS,$tree->{config}->{port});
	}

	# config->name element
	if(ref($tree->{config}->{name}) eq 'ARRAY'){
		display_error_and_exit("Error in $filename: config element can't have more than one name element");
	} elsif($tree->{config}->{name} ne undef){
		$SERVER_NAME = $tree->{config}->{name};
	}

	# config->nicklength element
	if(ref($tree->{config}->{nicklength}) eq 'ARRAY'){
		display_error_and_exit("Error in $filename: config element can't have more than one nicklength element");
	} elsif($tree->{config}->{nicklength} ne undef){
		$NICKNAME_LENGTH = $tree->{config}->{nicklength};
	}

	# config->network element
	if(ref($tree->{config}->{network}) eq 'ARRAY'){
		display_error_and_exit("Error in $filename: config element can't have more than one network element");
	} elsif($tree->{config}->{network} ne undef){
		$SERVER_NETWORK = $tree->{config}->{network};
	}

	# config->max_targets element
	if(ref($tree->{config}->{max_targets}) eq 'ARRAY'){
		display_error_and_exit("Error in $filename: config element can't have more than one max_targets element");
	} elsif($tree->{config}->{max_targets} ne undef){
		$MAX_TARGETS = $tree->{config}->{max_targets};
	}

	# config->max_channels element
	if(ref($tree->{config}->{max_channels}) eq 'ARRAY'){
		display_error_and_exit("Error in $filename: config element can't have more than one max_channels element");
	} elsif($tree->{config}->{max_channels} ne undef){
		$MAX_CHANNELS = $tree->{config}->{max_channels};
	}

	# config->info element
	if(ref($tree->{config}->{info}) eq 'ARRAY'){
		display_error_and_exit("Error in $filename: config element can't have more than one info element");
	} elsif($tree->{config}->{info} ne undef){
		$SERVER_INFO = $tree->{config}->{info};
	}

	# config->banner element
	if(ref($tree->{config}->{banner}) eq 'ARRAY'){
		display_error_and_exit("Error in $filename: config element can't have more than one banner element");
	} elsif($tree->{config}->{banner} ne undef){
		$BANNER = $tree->{config}->{banner};
	}

	# config->warn element
	if(ref($tree->{config}->{warn}) eq 'ARRAY'){
		display_error_and_exit("Error in $filename: config element can't have more than one warn element");
	} elsif($tree->{config}->{warn} ne undef){
		$WARNING = $tree->{config}->{warn};
	}

	# config->admin element
	if(ref($tree->{config}->{admin}) eq 'ARRAY'){
		my @a = @{$tree->{config}->{admin}};
		foreach my $ae (@a){
			push(@ADMIN,$ae);
		}
	} elsif($tree->{config}->{admin} ne undef){
		push(@ADMIN,$tree->{config}->{admin});
	}

	# config->description element
	if(ref($tree->{config}->{description}) eq 'ARRAY'){
		display_error_and_exit("Error in $filename: config element can't have more than one description element");
	} elsif($tree->{config}->{description} ne undef){
		$DESCRIPTION = $tree->{config}->{description};
	}
}

# ===========================
# | SUPPORT SUBROUTINES END |
# ===========================
