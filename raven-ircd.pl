#!/usr/bin/perl
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

# Scalar::Util -- A selection of general-utility scalar subroutines
use Scalar::Util qw(looks_like_number);

# Getopt::Long - Extended processing of command line options
use Getopt::Long;

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

# RavenConfigFile - Raven XML Configuration File
# Inherits from XML::TreePP -- Pure Perl implementation for parsing/writing XML documents
#                              By Yusuke Kawasaki
use RavenConfigFile;

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
use constant AUTH_FILE			=> 4;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~
# { OPERATOR LIST STRUCTURE }
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~
use constant OPERATOR_USERNAME	=> 0;
use constant OPERATOR_PASSWORD	=> 1;
use constant OPERATOR_IPMASK	=> 2;
use constant OPERATOR_FILE		=> 3;

# -----------
# | SCALARS |
# -----------

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# { CONFIGURATION FILE SETTINGS }
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# The declaration ID for a Raven IRCd config file
my $RAVEN_CONFIG_FILE_DECLARATION	= "raven-xml";
# Error displayed if Raven config file doesn't have proper ID
my $RAVEN_CONFIG_NO_DECLARATION		= "Raven configuration file declaration ('$RAVEN_CONFIG_FILE_DECLARATION') not found";
# Default config filename.
my $CONFIGURATION_FILE				= "default.xml";
# Where the server will look for config files besides the local directory.
my $CONFIGURATION_DIRECTORY_NAME	= "settings";

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# { APPLICATION DATA SETTINGS }
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# These are used by generate_banner(), and nowhere else.
my $APPLICATION_NAME		= "Raven IRCd";
my $VERSION					= "0.0352";
my $APPLICATION_DESCRIPTION	= "Raven IRCd is an IRC server written in Perl and POE";
my $APPLICATION_URL			= "https://github.com/danhetrick/raven-ircd";
my $PROGRAM_NAME			= 'raven-ircd.pl';

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~
# { SERVER DEFAULT SETTINGS }
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~
# These are the settings the server will use if no other
# setting is supplied by a configuration file.
my $SERVER_NAME					= "raven.irc.server";
my $NICKNAME_LENGTH				= 15;
my $SERVER_NETWORK				= "RavenNet";
my $MAX_TARGETS					= 4;
my $MAX_CHANNELS				= 15;
my $SERVER_INFO					= $APPLICATION_DESCRIPTION;
my $DEFAULT_PORT				= 6667;
my $DEFAULT_AUTH				= '*@*';
my $DEFAULT_ADMIN_LINE_1		= '-' x length("$APPLICATION_NAME $VERSION");
my $DEFAULT_ADMIN_LINE_2		= "$APPLICATION_NAME $VERSION";
my $DEFAULT_ADMIN_LINE_3		= '-' x length("$APPLICATION_NAME $VERSION");
my $DESCRIPTION					= "$APPLICATION_NAME $VERSION";
my $MOTD_FILE					= "motd.txt";
my $OPERSERV					= 0;
my $OPERSERV_NAME 				= "OperServ";
my $OPERSERV_CHANNEL_CONTROL	= 0;
my $OPERSERV_IRCNAME			= 'The OperServ bot';
my $DISPLAY_VERBOSE_TEXT		= 0;
my $DISPLAY_BANNER				= 1;
my $DISPLAY_WARNINGS			= 0;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# { CONFIGURATION FILE ELEMENTS }
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# These are the names of all root and child elements
# used in Raven IRCd configuration files.

# ------------------
# ( IMPORT ELEMENT )
# ------------------
# Root element
my $IMPORT_ROOT_ELEMENT			= "import";

# ------------------
# ( CONFIG ELEMENT )
# ------------------
# Root element
my $CONFIG_ROOT_ELEMENT			= "config";
# Child elements
my $CONFIG_CHILD_PORT			= "port";
my $CONFIG_CHILD_NAME			= "name";
my $CONFIG_CHILD_NICKLENGTH		= "nicklength";
my $CONFIG_CHILD_NETWORK		= "network";
my $CONFIG_CHILD_MAXTARGETS		= "max_targets";
my $CONFIG_CHILD_MAXCHANNELS	= "max_channels";
my $CONFIG_CHILD_INFO			= "info";
my $CONFIG_CHILD_ADMIN			= "admin";
my $CONFIG_CHILD_DESCRIPTION	= "description";
my $CONFIG_CHILD_MOTD			= "motd";

# ----------------
# ( AUTH ELEMENT )
# ----------------
# Root element
my $AUTH_ROOT_ELEMENT			= "auth";
# Child elements
my $AUTH_CHILD_MASK				= "mask";
my $AUTH_CHILD_PASSWORD			= "password";
my $AUTH_CHILD_SPOOF			= "spoof";
my $AUTH_CHILD_NOTILDE			= "no_tilde";

# --------------------
# ( OPERATOR ELEMENT )
# --------------------
# Root element
my $OPERATOR_ROOT_ELEMENT		= "operator";
# Child elements
my $OPERATOR_CHILD_USERNAME		= "username";
my $OPERATOR_CHILD_PASSWORD		= "password";
my $OPERATOR_CHILD_IPMASK		= "ipmask";

# --------------------
# ( OPERSERV ELEMENT )
# --------------------
# Root element
my $OPERSERV_ROOT_ELEMENT		= "operserv";
# Child elements
my $OPERSERV_CHILD_USE			= "use";
my $OPERSERV_CHILD_NICK			= "nick";
my $OPERSERV_CHILD_CONTROL		= "control";
my $OPERSERV_CHILD_USERNAME		= "username";

# ----------
# | ARRAYS |
# ----------

# These arrays are used in _start() to set the listening ports, 
# the list of authorized connections, and the list of operator accounts
# the server will use. They are populated by the data supplied in
# configuration files, loaded into memory by load_settings_from_xml_config_file().
# @LISTENER_PORTS is an array of scalars, each containing a port number.
# @AUTHS is an array of arrays, each mapped using AUTH LIST STRUCTURE
# set in the CONSTANTS. @OPERATORS is an array of arrays, each mapped using
# OPERATOR LIST STRUCTURE set in the CONSTANTS.
# @IMPORTED_FILES contains a list of all the files imported by configuration
# files, so we can display them to the user with verbose() after we've
# loaded them.
# @ADMIN contains the three lines returned by the IRC command /admin.
# It's also populated by load_settings_from_xml_config_file(), and then sanity
# checked by admin_setting_sanity_check(), which makes sure that the array only
# contains 3 items and sets them to default values if they are missing.
# @MOTD contains the message of the day.
my @LISTENER_PORTS			= ();	# List of server listening ports to use
my @AUTHS					= ();	# List of auth entries
my @OPERATORS				= ();	# List of operator entries
my @IMPORTED_FILES			= ();	# List of imported files
my @ADMIN					= ();	# Text returned by the /admin command
my @MOTD					= ();	# Message of the Day
my @CONFIG_ELEMENT_FILES	= (); 	# A list of files with config elements

# ===============
# | GLOBALS END |
# ===============

# ======================
# | MAIN PROGRAM BEGIN |
# ======================

# Handle any commandline options
my $cmdline_config_file = '';
Getopt::Long::Configure ("bundling");
GetOptions ('config|c=s'   	=> \$cmdline_config_file,
			'warn|w'		=> sub { $DISPLAY_WARNINGS = 1; },
			'verbose|v'		=> sub { $DISPLAY_VERBOSE_TEXT = 1; },
			'nobanner|n'	=> sub { $DISPLAY_BANNER = 0; },
	        'quiet|q'		=> sub { $DISPLAY_VERBOSE_TEXT = 0; $DISPLAY_BANNER = 0; $DISPLAY_WARNINGS = 0; },
			'help|h'	=> sub { display_program_usage(); exit; }
			 );

# Now it's time to load configuration files!

# If a config file is set with commandline options, select that
# file to load (rather than default.xml).
if($cmdline_config_file){ $CONFIGURATION_FILE=$cmdline_config_file; }

# Look for the configuration file in the local directory or the config/ directory.
my $found_configuration_file = find_file_in_home_or_settings_directory($CONFIGURATION_FILE);

# If configuration file is found, load it. If the configure file is *not* found,
# use default settings and warn the user.  No matter what, print the banner to
# the console if verbosity is turned on.
if($found_configuration_file){
	# Configuration file found, load it into memory.
	load_settings_from_xml_config_file($found_configuration_file);
	# Display banner unless configured otherwise
	if($DISPLAY_BANNER==1){ print generate_banner(); }
	# Let the user know what configuration file was loaded.
	verbose("Loaded configuration file '$found_configuration_file'");
} else {
	# Configuration file not found, error and exit
	display_error_and_exit("Configuration file '$CONFIGURATION_FILE' not found")
}
# Display any files imported by any configuration files
if(scalar @IMPORTED_FILES>=1){
	foreach my $i (@IMPORTED_FILES){
		verbose("Imported configuration file '$i'");
	}
}

# Do a sanity check for the config->admin element
# No more than three entries are allowed, so make sure that
# @ADMIN (the array that contains the entries) has no more
# or no less than 3 entries. Since it's not really a critical
# setting, we'll only warn the user if there's too many, rather
# than error and exit, and we'll only use the first three
# entries.
admin_setting_sanity_check();

# Set up the Message of the Day! $MOTD_FILE (default: motd.txt) has
# its value set by the config file, in config->motd. Here, we look
# for the MOTD file, and if it's found, open it and read it, populating
# @MOTD with its contents. As with configuration files, the program
# first checks to see if $MOTD_FILE contains a complete path,
# and if not, looks for it in the same directory as this program
# and the settings directory.
my $motd = find_file_in_home_or_settings_directory($MOTD_FILE);
if($motd){
	verbose("Added MOTD from '$motd'");
	open(FILE,"<$motd") or display_error_and_exit("Error opening MOTD file '$motd'");
	while ( my $line = <FILE> ) {
        chomp $line;
        push(@MOTD,$line);
    }
    close FILE;
} else {
	# MOTD fine wasn't found, so warn the user and populate @MOTD
	# with an error message (of sorts).
	warning("MOTD file not found! MOTD set to 'No MOTD set'");
	push(@MOTD, "No MOTD set");
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
    motd 		=> \@MOTD,
);

# Spawn our RavenIRCd instance, and pass it our server configuration.
my $pocosi = RavenIRCd->spawn( config => \%config );

# If the OperServ is turned on, add it and configure it.
if($OPERSERV==1){
	# Load libraries
	use POE::Component::Server::IRC::Plugin::OperServ;
	use OperServ;

	# Enable OperServ and set whether its in channel control more
	RavenIRCd::enable_operserv($OPERSERV_NAME,$OPERSERV_CHANNEL_CONTROL);

	# Make sure OperSev knows its own name :-)
	OperServ::set_opserv_name($OPERSERV_NAME);
	OperServ::set_opserv_ircname($OPERSERV_IRCNAME);

	# Add it!
	$pocosi->plugin_add(
		"OperServ",
		OperServ->new(),
	);

	# Let the user know OperServ is turned on, and if it's in
	# channel control mode or not.
	if($OPERSERV_CHANNEL_CONTROL==1){
		verbose("Activated OperServ ($OPERSERV_NAME) in channel control mode");
	} else {
		verbose("Activated OperServ ($OPERSERV_NAME)");
	}
}


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

#	display_program_usage()
#	remove_duplicates_from_array()
#	timestamp()
#	verbose()
#	generate_banner()
#	logo()
#	display_error_and_exit()
#	warning()

# -------------------------------
# | Configuration File Handling |
# -------------------------------

#	admin_setting_sanity_check()
#	find_file_in_home_or_settings_directory()
#	load_settings_from_xml_config_file()

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
#               load_settings_from_xml_config_file() with data supplied in the configuration
#               files.
sub _start {
    my ($kernel, $heap) = @_[KERNEL, HEAP];
 
 	# Make sure we get all events
    $heap->{ircd}->yield('register', 'all');

    # Add authorized connections
    if(scalar @AUTHS >=1){
    	# Add authorized connections from the list in @AUTHS
    	my @aus = ();
	    foreach my $a (@AUTHS){
	    	my @entry = @{$a};
	    	push(@aus,$entry[AUTH_FILE]);
	    	$heap->{ircd}->add_auth(
		        mask		=> $entry[AUTH_MASK],
		        password	=> $entry[AUTH_PASSWORD],
		        spoof		=> $entry[AUTH_SPOOF],
		        no_tilde	=> $entry[AUTH_TILDE],
    		); 
    	}

    	# Give user a list of filenames containing auth data
    	# with the duplicates consolidated
    	foreach my $f (remove_duplicates_from_array(@aus)) {
			verbose("Adding authorized entries from '$f'");
		}
		# Display how many auth entries were loaded
		my $count = scalar @AUTHS;
		if($count==1){
			verbose ("1 auth entry loaded");
		} else {
			verbose ("$count auth entries loaded");
		}
    } else {
    		# @AUTHS is empty, so let the user know and use the default auth entry.
    		warning("No authorized entries found! Using $DEFAULT_AUTH as the auth");
    		$heap->{ircd}->add_auth(
	        	mask		=> $DEFAULT_AUTH,
    		); 
    }
 
    # Add IRC operators
    if(scalar @OPERATORS>=1){
    	# Add operators from the list in @OPERATORS
    	# verbose("Adding operator account(s)");
    	my @files = ();
	    foreach my $o (@OPERATORS){
			my @entry = @{$o};
			push(@files,$entry[OPERATOR_FILE]);
			$heap->{ircd}->add_operator(
		        {
		            username	=> $entry[OPERATOR_USERNAME],
		            password	=> $entry[OPERATOR_PASSWORD],
		            ipmask		=> $entry[OPERATOR_IPMASK],
		        }
		    );
		}
		# Give user a list of filenames containing auth data
    	# with the duplicates consolidated
		foreach my $f (remove_duplicates_from_array(@files)) {
			verbose("Added operator entries from '$f'");
		}
		# Display how many operator accounts were loaded
		my $count = scalar @OPERATORS;
		if($count==1){
			verbose ("1 operator entry loaded");
		} else {
			verbose ("$count operator entries loaded");
		}
	} else {
		# @OPERATORS is empty, so let the user know and start with no operators.
		warning('No operator entries found! Server will start without operators');
	}

	# Add listening port(s)
    if(scalar @LISTENER_PORTS >=1){
    	# Add ports from the list in @LISTENER_PORTS
	    foreach my $p (@LISTENER_PORTS){
	    	verbose("Added a listener on port '$p'");
	    	$heap->{ircd}->add_listener(port => $p);
	    }
	} else {
		# @LISTENER_PORTS is empty, so let the user know and use the default port.
		$heap->{ircd}->add_listener(port => $DEFAULT_PORT);
		warning("No listening ports found! Using $DEFAULT_PORT as the listening port");
	}
}

# --------------------
# | User Interaction |
# --------------------

# remove_duplicates_from_array()
# Arguments: 1 (array)
# Returns:  Array
# Description:  Removes all duplicates from an array, and returns the clean version.
sub remove_duplicates_from_array {
    my %seen;
    grep !$seen{$_}++, @_;
}

# display_program_usage()
# Arguments: None
# Returns:  Nothing
# Description:  Displays usage information
sub display_program_usage {
	print generate_banner();
	print "perl $PROGRAM_NAME [OPTIONS] FILENAME\n\n";
	print "Options:\n";
	print "--help or -h			Displays usage information\n";
	print "--config FILE or -c FILE	Runs $APPLICATION_NAME with default settings\n";
	print "--warn or -w			Turns warnings on\n";
	print "--verbose or -v			Turns verbose on\n";
	print "--quiet or -q			Run silently\n";
	print "--nobanner or -n		Don't display $APPLICATION_NAME banner\n\n";
	print "Options can be bundled; so, to turn on verbose and warning, use -vw\n";
}

# timestamp()
# Arguments: None
# Returns:  Scalar (timestamp)
# Description:  Generates a timestamp for the current time/date,
#               and returns it. This subroutine is used to generate the
#               timestamps for warning() and verbose().
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
	if($DISPLAY_VERBOSE_TEXT==1){
		print "$time $txt\n";
	}
}

# warning()
# Arguments: 1 (scalar, warning text)
# Returns: Nothing
# Description: Displays a timestamped warning to the user; only displayed
#              if verbosity is turned on. Warnings will *always* display
#              if warnings are turned on, even if verbosity is turned off.
sub warning {
	my $msg = shift;
	my $time = timestamp();
	if($DISPLAY_WARNINGS==1){
		print "$time WARNING: $msg\n";
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
#
# ██████╗  █████╗ ██╗   ██╗███████╗███╗   ██╗	I
# ██╔══██╗██╔══██╗██║   ██║██╔════╝████╗  ██║	R
# ██████╔╝███████║██║   ██║█████╗  ██╔██╗ ██║	C
# ██╔══██╗██╔══██║╚██╗ ██╔╝██╔══╝  ██║╚██╗██║	d
# ██║  ██║██║  ██║ ╚████╔╝ ███████╗██║ ╚████║	*
# ╚═╝  ╚═╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝╚═╝  ╚═══╝	*
#                                  VERSION 0.0352
sub generate_banner {
	my $DISPLAY_BANNER_PADDING = "-";	# What the spaces to the left of the text is filled with
	my $LOGO_WIDTH	= 49;		# The width (give or take) of the text banner generated with logo()

	my $b = "\n".logo().(' ' x ($LOGO_WIDTH - length("VERSION $VERSION")))."VERSION $VERSION\n\n";
	return $b;
}

# logo()
# Arguments: None
# Returns: Scalar
# Description: Returns the text logo for Raven IRCd. This is only
#              used for the startup banner.
 sub logo {
	return << 'END';
██████╗  █████╗ ██╗   ██╗███████╗███╗   ██╗	I
██╔══██╗██╔══██╗██║   ██║██╔════╝████╗  ██║	R
██████╔╝███████║██║   ██║█████╗  ██╔██╗ ██║	C
██╔══██╗██╔══██║╚██╗ ██╔╝██╔══╝  ██║╚██╗██║	d
██║  ██║██║  ██║ ╚████╔╝ ███████╗██║ ╚████║	*
╚═╝  ╚═╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝╚═╝  ╚═══╝	*
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

# -------------------------------
# | Configuration File Handling |
# -------------------------------

# admin_setting_sanity_check()
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
sub admin_setting_sanity_check {
	if(scalar @ADMIN==3) { return; }
	if(scalar @ADMIN>3){
		warning("Too many admin elements set; using only the first three");
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

# find_file_in_home_or_settings_directory()
# Arguments: 1 (scalar, filename)
# Returns: Scalar (filename)
# Description: Looks for a given configuration file in the several directories.
#              This subroutine was written with cross-platform compatability in
#              mind; in theory, this should work on any platform that can run
#              Perl (so, OSX, *NIX, Linux, Windows, etc). Not "expensive" to
#              run, as it doesn't do directory searches.
sub find_file_in_home_or_settings_directory {
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

# load_settings_from_xml_config_file()
# Arguments: 1 (scalar, filename)
# Returns: Nothing
# Description: Opens up an XML config file and reads settings from it.
#              Recursive, so that config files can </import> other
#              config files.
sub load_settings_from_xml_config_file {
	my $filename = shift;

	# Create RavenConfigFile object
	my $rcf = RavenConfigFile->new();

	# Set declaration ID
	$rcf->set_declaration_id($RAVEN_CONFIG_FILE_DECLARATION);

	# Set no declaration error text
	$rcf->set_id_error($RAVEN_CONFIG_NO_DECLARATION);

	# XML declaration must be the first line of the file
	$rcf->set( require_xml_decl => 1 );

	# Load our configuration file
	my $tree = $rcf->parsefile( $filename );

	# If the parsed tree is empty, there's nothing to parse; exit subroutine
	# This may occur because all the elements in the configuration file are
	# commented out.
	if($tree eq '') { return; }

	# ------------------
	# | IMPORT ELEMENT |
	# ------------------

	# Allows importing of config files.

	if(ref($tree->{$IMPORT_ROOT_ELEMENT}) eq 'ARRAY'){
		foreach my $i (@{$tree->{$IMPORT_ROOT_ELEMENT}}) {
			# Multiple import elements
			$i = find_file_in_home_or_settings_directory($i);
			if(!$i){
				# Imported file not found; alert user and exit
				display_error_and_exit("Configuration file '$filename' not found");
			}
			# Recursively call load_settings_from_xml_config_file() to load in the settings
			# from the imported file
			load_settings_from_xml_config_file($i);
			# Add imported file to the imported file list
			push(@IMPORTED_FILES,$i);
		}
	} elsif($tree->{$IMPORT_ROOT_ELEMENT} ne undef){
		# Single import element
		my $f = find_file_in_home_or_settings_directory($tree->{$IMPORT_ROOT_ELEMENT});
		if(!$f){
			# Imported file not found; alert user and exit
			display_error_and_exit("Configuration file '$filename' not found");
		}
		# Recursively call load_settings_from_xml_config_file() to load in the settings
		# from the imported file
		load_settings_from_xml_config_file($f);
		# Add imported file to the imported file list
		push(@IMPORTED_FILES,$f);
	}

	# --------------------
	# | OPERATOR ELEMENT |
	# --------------------
	
	# Adds an operator to the IRC server.  Ipmask is optional.

	if(ref($tree->{$OPERATOR_ROOT_ELEMENT}) eq 'ARRAY'){
		foreach my $a (@{$tree->{$OPERATOR_ROOT_ELEMENT}}) {
			# Multiple operator elements
			my @op = ();

			# operator->username
			if(ref($a->{$OPERATOR_CHILD_USERNAME}) eq 'ARRAY'){
				display_error_and_exit("Error in $filename: $OPERATOR_ROOT_ELEMENT element can't have more than one $OPERATOR_CHILD_USERNAME element");
			}
			if($a->{$OPERATOR_CHILD_USERNAME} ne undef){
				push(@op,$a->{$OPERATOR_CHILD_USERNAME});
			} else {
				display_error_and_exit("Error in $filename: $OPERATOR_ROOT_ELEMENT element missing a $OPERATOR_CHILD_USERNAME element");
			}

			# operator->password
			if(ref($a->{$OPERATOR_CHILD_PASSWORD}) eq 'ARRAY'){
				display_error_and_exit("Error in $filename: $OPERATOR_ROOT_ELEMENT element can't have more than one $OPERATOR_CHILD_PASSWORD element");
			}
			if($a->{$OPERATOR_CHILD_PASSWORD} ne undef){
				push(@op,$a->{$OPERATOR_CHILD_PASSWORD});
			} else {
				display_error_and_exit("Error in $filename: $OPERATOR_ROOT_ELEMENT element missing a $OPERATOR_CHILD_PASSWORD element");
			}
			
			# operator->ipmask
			if(ref($a->{$OPERATOR_CHILD_IPMASK}) eq 'ARRAY'){
				display_error_and_exit("Error in $filename: $OPERATOR_ROOT_ELEMENT element can't have more than one $OPERATOR_CHILD_IPMASK element");
			}
			if($a->{$OPERATOR_CHILD_IPMASK} ne undef){
				push(@op,$a->{$OPERATOR_CHILD_IPMASK});
			} else {
				push(@op,undef);
			}

			# Add filename to the operator entry
			push(@op, $filename);

			# Add operator entry to the operator list
			push(@OPERATORS,\@op);
		}
	} elsif($tree->{$OPERATOR_ROOT_ELEMENT} ne undef){
		# Single operator element
		my @op = ();

		# operator->username
		if($tree->{$OPERATOR_ROOT_ELEMENT}->{$OPERATOR_CHILD_USERNAME} ne undef){
			if(ref($tree->{$OPERATOR_ROOT_ELEMENT}->{$OPERATOR_CHILD_USERNAME}) eq 'ARRAY'){
				display_error_and_exit("Error in $filename: $OPERATOR_ROOT_ELEMENT element can't have more than one $OPERATOR_CHILD_USERNAME element");
			}
			push (@op,$tree->{$OPERATOR_ROOT_ELEMENT}->{$OPERATOR_CHILD_USERNAME});
		} else {
			display_error_and_exit("Error in $filename: $OPERATOR_ROOT_ELEMENT element missing a $OPERATOR_CHILD_USERNAME element");
		}

		# operator->password
		if($tree->{$OPERATOR_ROOT_ELEMENT}->{$OPERATOR_CHILD_PASSWORD} ne undef){
			if(ref($tree->{$OPERATOR_ROOT_ELEMENT}->{$OPERATOR_CHILD_PASSWORD}) eq 'ARRAY'){
				display_error_and_exit("Error in $filename: $OPERATOR_ROOT_ELEMENT element can't have more than one $OPERATOR_CHILD_PASSWORD element");
			}
			push(@op,$tree->{$OPERATOR_ROOT_ELEMENT}->{$OPERATOR_CHILD_PASSWORD});
		} else {
			display_error_and_exit("Error in $filename: $OPERATOR_ROOT_ELEMENT element missing a $OPERATOR_CHILD_PASSWORD element");
		}

		# operator->ipmask
		if($tree->{$OPERATOR_ROOT_ELEMENT}->{$OPERATOR_CHILD_IPMASK} ne undef){
			if(ref($tree->{$OPERATOR_ROOT_ELEMENT}->{$OPERATOR_CHILD_IPMASK}) eq 'ARRAY'){
				display_error_and_exit("Error in $filename: $OPERATOR_ROOT_ELEMENT element can't have more than one $OPERATOR_CHILD_IPMASK element");
			}
			push(@op,$tree->{$OPERATOR_ROOT_ELEMENT}->{$OPERATOR_CHILD_IPMASK});
		} else {
			push(@op,undef);
		}

		# Add filename to the operator entry
		push(@op, $filename);

		# Add operator entry to the operator list
		push(@OPERATORS,\@op);
	}

	# ----------------
	# | AUTH ELEMENT |
	# ----------------

	# Configures authorized connections.

	if(ref($tree->{$AUTH_ROOT_ELEMENT}) eq 'ARRAY'){
		foreach my $a (@{$tree->{$AUTH_ROOT_ELEMENT}}) {
			# Multiple auth elements
			my @auth = ();

			# auth->mask
			if(ref($a->{$AUTH_CHILD_MASK}) eq 'ARRAY'){
				display_error_and_exit("Error in $filename: $AUTH_ROOT_ELEMENT element can't have more than one $AUTH_CHILD_MASK element");
			}
			if($a->{$AUTH_CHILD_MASK} ne undef){
				push(@auth,$a->{$AUTH_CHILD_MASK});
			} else {
				display_error_and_exit("Error in $filename: $AUTH_ROOT_ELEMENT element missing a $AUTH_CHILD_MASK element");
			}

			# auth->password
			if(ref($a->{$AUTH_CHILD_PASSWORD}) eq 'ARRAY'){
				display_error_and_exit("Error in $filename: $AUTH_ROOT_ELEMENT element can't have more than one $AUTH_CHILD_PASSWORD element");
			}
			if($a->{$AUTH_CHILD_PASSWORD} ne undef){
				push(@auth,$a->{$AUTH_CHILD_PASSWORD});
			} else {
				push(@auth,undef);
			}

			# auth->spoof
			if(ref($a->{$AUTH_CHILD_SPOOF}) eq 'ARRAY'){
				display_error_and_exit("Error in $filename: $AUTH_ROOT_ELEMENT element can't have more than one $AUTH_CHILD_SPOOF element");
			}
			if($a->{$AUTH_CHILD_SPOOF} ne undef){
				push(@auth,$a->{$AUTH_CHILD_SPOOF});
			} else {
				push(@auth,undef);
			}

			# auth->no_tilde
			if(ref($a->{$AUTH_CHILD_NOTILDE}) eq 'ARRAY'){
				display_error_and_exit("Error in $filename: $AUTH_ROOT_ELEMENT element can't have more than one $AUTH_CHILD_NOTILDE element");
			}
			if($a->{$AUTH_CHILD_NOTILDE} ne undef){
				# Sanity check for no_tilde; it should either be 1 or 0, and nothing else
				if(($a->{$AUTH_CHILD_NOTILDE} eq '0')||($a->{$AUTH_CHILD_NOTILDE} eq '1')){}else{
					display_error_and_exit("Error in $filename: '$a->{no_tilde}' is not a valid setting for $AUTH_ROOT_ELEMENT->$AUTH_CHILD_NOTILDE (must be 0 or 1)");
				}
				push(@auth,$a->{$AUTH_CHILD_NOTILDE});
			} else {
				push(@auth,undef);
			}

			# Add filename to the auth entry
			push(@auth, $filename);

			# Add auth entry to the auth list
			push(@AUTHS,\@auth);
		}
	} elsif($tree->{$AUTH_ROOT_ELEMENT} ne undef){
		# Single auth element
		my @auth = ();

		# auth->mask
		if(ref($tree->{$AUTH_ROOT_ELEMENT}->{$AUTH_CHILD_MASK}) eq 'ARRAY'){
			display_error_and_exit("Error in $filename: $AUTH_ROOT_ELEMENT element can't have more than one $AUTH_CHILD_MASK element");
		}
		if($tree->{$AUTH_ROOT_ELEMENT}->{$AUTH_CHILD_MASK} ne undef){
			push (@auth,$tree->{$AUTH_ROOT_ELEMENT}->{$AUTH_CHILD_MASK});
		} else {
			display_error_and_exit("Error in $filename: $AUTH_ROOT_ELEMENT element missing a $AUTH_CHILD_MASK element");
		}

		# auth->password
		if(ref($tree->{$AUTH_ROOT_ELEMENT}->{$AUTH_CHILD_PASSWORD}) eq 'ARRAY'){
			display_error_and_exit("Error in $filename: $AUTH_ROOT_ELEMENT element can't have more than one $AUTH_CHILD_PASSWORD element");
		}
		if($tree->{$AUTH_ROOT_ELEMENT}->{$AUTH_CHILD_PASSWORD} ne undef){
			push(@auth,$tree->{$AUTH_ROOT_ELEMENT}->{$AUTH_CHILD_PASSWORD});
		} else {
			push(@auth,undef);
		}

		# auth->spoof
		if(ref($tree->{$AUTH_ROOT_ELEMENT}->{$AUTH_CHILD_SPOOF}) eq 'ARRAY'){
			display_error_and_exit("Error in $filename: $AUTH_ROOT_ELEMENT element can't have more than one $AUTH_CHILD_SPOOF element");
		}
		if($tree->{$AUTH_ROOT_ELEMENT}->{$AUTH_CHILD_SPOOF} ne undef){
			push(@auth,$tree->{$AUTH_ROOT_ELEMENT}->{$AUTH_CHILD_SPOOF});
		} else {
			push(@auth,undef);
		}

		# auth->no_tilde
		if(ref($tree->{$AUTH_ROOT_ELEMENT}->{$AUTH_CHILD_NOTILDE}) eq 'ARRAY'){
			display_error_and_exit("Error in $filename: $AUTH_ROOT_ELEMENT element can't have more than one $AUTH_CHILD_NOTILDE element");
		}
		if($tree->{$AUTH_ROOT_ELEMENT}->{$AUTH_CHILD_NOTILDE} ne undef){
			# Sanity check for auth->no_tilde; it should either be 1 or 0, and nothing else
			if(($tree->{$AUTH_ROOT_ELEMENT}->{$AUTH_CHILD_NOTILDE} eq '0')||($tree->{$AUTH_ROOT_ELEMENT}->{$AUTH_CHILD_NOTILDE} eq '1')){}else{
				display_error_and_exit("Error in $filename: '$tree->{$AUTH_ROOT_ELEMENT}->{no_tilde}' is not a valid setting for $AUTH_ROOT_ELEMENT->$AUTH_CHILD_NOTILDE (must be 0 or 1)");
			}
			push(@auth,$tree->{$AUTH_ROOT_ELEMENT}->{$AUTH_CHILD_NOTILDE});
		} else {
			push(@auth,undef);
		}

		# Add filename to the auth entry
		push(@auth, $filename);

		# Add auth entry to the auth list
		push(@AUTHS,\@auth);
	}

	# --------------------
	# | OPERSERV ELEMENT |
	# --------------------

	# Activates and configures the OperServ bot

	if(ref($tree->{$OPERSERV_ROOT_ELEMENT}) eq 'ARRAY'){
		# Multiple operserv elements
		display_error_and_exit("Error in $filename: multiple $OPERSERV_ROOT_ELEMENT elements are not allowed");
	} elsif($tree->{$OPERSERV_ROOT_ELEMENT} ne undef){
		# Single operserv element

		# operserv->use
		if(ref($tree->{$OPERSERV_ROOT_ELEMENT}->{$OPERSERV_CHILD_USE}) eq 'ARRAY'){
			display_error_and_exit("Error in $filename: $OPERSERV_ROOT_ELEMENT element can't have more than one $OPERSERV_CHILD_USE element");
		}
		if($tree->{$OPERSERV_ROOT_ELEMENT}->{$OPERSERV_CHILD_USE} ne undef){
			# Sanity check for operserv->use; it should either be 1 or 0, and nothing else
			if(($tree->{$OPERSERV_ROOT_ELEMENT}->{$OPERSERV_CHILD_USE} eq '0')||($tree->{$OPERSERV_ROOT_ELEMENT}->{$OPERSERV_CHILD_USE} eq '1')){}else{
				display_error_and_exit("Error in $filename: '$tree->{$OPERSERV_ROOT_ELEMENT}->{$OPERSERV_CHILD_USE}' is not a valid setting for $OPERSERV_ROOT_ELEMENT->$OPERSERV_CHILD_USE (must be 0 or 1)");
			}
			$OPERSERV = $tree->{$OPERSERV_ROOT_ELEMENT}->{$OPERSERV_CHILD_USE};
		}

		# operserv->nick
		if(ref($tree->{$OPERSERV_ROOT_ELEMENT}->{$OPERSERV_CHILD_NICK}) eq 'ARRAY'){
			display_error_and_exit("Error in $filename: $OPERSERV_ROOT_ELEMENT element can't have more than one $OPERSERV_CHILD_NICK element");
		}
		if($tree->{$OPERSERV_ROOT_ELEMENT}->{$OPERSERV_CHILD_NICK} ne undef){
			$OPERSERV_NAME = $tree->{$OPERSERV_ROOT_ELEMENT}->{$OPERSERV_CHILD_NICK};
		}

		# operserv->nick
		if(ref($tree->{$OPERSERV_ROOT_ELEMENT}->{$OPERSERV_CHILD_USERNAME}) eq 'ARRAY'){
			display_error_and_exit("Error in $filename: $OPERSERV_ROOT_ELEMENT element can't have more than one $OPERSERV_CHILD_USERNAME element");
		}
		if($tree->{$OPERSERV_ROOT_ELEMENT}->{$OPERSERV_CHILD_USERNAME} ne undef){
			$OPERSERV_IRCNAME = $tree->{$OPERSERV_ROOT_ELEMENT}->{$OPERSERV_CHILD_USERNAME};
		}

		# operserv->control
		if(ref($tree->{$OPERSERV_ROOT_ELEMENT}->{$OPERSERV_CHILD_CONTROL}) eq 'ARRAY'){
			display_error_and_exit("Error in $filename: $OPERSERV_ROOT_ELEMENT element can't have more than one $OPERSERV_CHILD_CONTROL element");
		}
		if($tree->{$OPERSERV_ROOT_ELEMENT}->{$OPERSERV_CHILD_CONTROL} ne undef){
			# Sanity check for operserv->control; it should either be 1 or 0, and nothing else
			if(($tree->{$OPERSERV_ROOT_ELEMENT}->{$OPERSERV_CHILD_CONTROL} eq '0')||($tree->{$OPERSERV_ROOT_ELEMENT}->{$OPERSERV_CHILD_CONTROL} eq '1')){}else{
				display_error_and_exit("Error in $filename: '$tree->{$OPERSERV_ROOT_ELEMENT}->{control}' is not a valid setting for $OPERSERV_ROOT_ELEMENT->$OPERSERV_CHILD_CONTROL (must be 0 or 1)");
			}
			$OPERSERV_CHANNEL_CONTROL = $tree->{$OPERSERV_ROOT_ELEMENT}->{$OPERSERV_CHILD_CONTROL};
		}
	}

	# ------------------
	# | CONFIG ELEMENT |
	# ------------------

	# Allows for server configuration.  Multiple port elements are allowed. All elements are optional;
	# default settings will be used for all missing elements.

	# config->port
	if(ref($tree->{$CONFIG_ROOT_ELEMENT}->{port}) eq 'ARRAY'){
		foreach my $p (@{$tree->{$CONFIG_ROOT_ELEMENT}->{$CONFIG_CHILD_PORT}}) {
			# Sanity check for config->port; must be numeric
			if (looks_like_number($p)) {}else{
				display_error_and_exit("Error in $filename: '$p' is not a valid setting for $CONFIG_ROOT_ELEMENT->$CONFIG_CHILD_PORT (must be numeric)");
			}
			push(@LISTENER_PORTS,$p);
		}
	} elsif($tree->{$CONFIG_ROOT_ELEMENT}->{$CONFIG_CHILD_PORT} ne undef){
		# Sanity check for config->port; must be numeric
		if (looks_like_number($tree->{$CONFIG_ROOT_ELEMENT}->{$CONFIG_CHILD_PORT})) {}else{
			display_error_and_exit("Error in $filename: '$tree->{$CONFIG_ROOT_ELEMENT}->{port}' is not a valid setting for $CONFIG_ROOT_ELEMENT->$CONFIG_CHILD_PORT (must be numeric)");
		}
		push(@LISTENER_PORTS,$tree->{$CONFIG_ROOT_ELEMENT}->{$CONFIG_CHILD_PORT});
	}

	# config->name
	if(ref($tree->{$CONFIG_ROOT_ELEMENT}->{$CONFIG_CHILD_NAME}) eq 'ARRAY'){
		display_error_and_exit("Error in $filename: $CONFIG_ROOT_ELEMENT element can't have more than one $CONFIG_CHILD_NAME element");
	} elsif($tree->{$CONFIG_ROOT_ELEMENT}->{$CONFIG_CHILD_NAME} ne undef){
		$SERVER_NAME = $tree->{$CONFIG_ROOT_ELEMENT}->{$CONFIG_CHILD_NAME};
	}

	# config->nicklength
	if(ref($tree->{$CONFIG_ROOT_ELEMENT}->{$CONFIG_CHILD_NICKLENGTH}) eq 'ARRAY'){
		display_error_and_exit("Error in $filename: $CONFIG_ROOT_ELEMENT element can't have more than one $CONFIG_CHILD_NICKLENGTH element");
	} elsif($tree->{$CONFIG_ROOT_ELEMENT}->{$CONFIG_CHILD_NICKLENGTH} ne undef){
		# Sanity check for config->nicklength; must be numeric
		if (looks_like_number($tree->{$CONFIG_ROOT_ELEMENT}->{$CONFIG_CHILD_NICKLENGTH})) {}else{
			display_error_and_exit("Error in $filename: '$tree->{$CONFIG_ROOT_ELEMENT}->{nicklength}' is not a valid setting for $CONFIG_ROOT_ELEMENT->$CONFIG_CHILD_NICKLENGTH (must be numeric)");
		}
		$NICKNAME_LENGTH = $tree->{$CONFIG_ROOT_ELEMENT}->{$CONFIG_CHILD_NICKLENGTH};
	}

	# config->network
	if(ref($tree->{$CONFIG_ROOT_ELEMENT}->{$CONFIG_CHILD_NETWORK}) eq 'ARRAY'){
		display_error_and_exit("Error in $filename: $CONFIG_ROOT_ELEMENT element can't have more than one $CONFIG_CHILD_NETWORK element");
	} elsif($tree->{$CONFIG_ROOT_ELEMENT}->{$CONFIG_CHILD_NETWORK} ne undef){
		$SERVER_NETWORK = $tree->{$CONFIG_ROOT_ELEMENT}->{$CONFIG_CHILD_NETWORK};
	}

	# config->max_targets
	if(ref($tree->{$CONFIG_ROOT_ELEMENT}->{$CONFIG_CHILD_MAXTARGETS}) eq 'ARRAY'){
		display_error_and_exit("Error in $filename: $CONFIG_ROOT_ELEMENT element can't have more than one $CONFIG_CHILD_MAXTARGETS element");
	} elsif($tree->{$CONFIG_ROOT_ELEMENT}->{$CONFIG_CHILD_MAXTARGETS} ne undef){
		# Sanity check for config->max_targets; must be numeric
		if (looks_like_number($tree->{$CONFIG_ROOT_ELEMENT}->{$CONFIG_CHILD_MAXTARGETS})) {}else{
			display_error_and_exit("Error in $filename: '$tree->{$CONFIG_ROOT_ELEMENT}->{max_targets}' is not a valid setting for $CONFIG_ROOT_ELEMENT->$CONFIG_CHILD_MAXTARGETS (must be numeric)");
		}
		$MAX_TARGETS = $tree->{$CONFIG_ROOT_ELEMENT}->{$CONFIG_CHILD_MAXTARGETS};
	}

	# config->max_channels
	if(ref($tree->{$CONFIG_ROOT_ELEMENT}->{$CONFIG_CHILD_MAXCHANNELS}) eq 'ARRAY'){
		display_error_and_exit("Error in $filename: $CONFIG_ROOT_ELEMENT element can't have more than one $CONFIG_CHILD_MAXCHANNELS element");
	} elsif($tree->{$CONFIG_ROOT_ELEMENT}->{$CONFIG_CHILD_MAXCHANNELS} ne undef){
		# Sanity check for config->max_channels; must be numeric
		if (looks_like_number($tree->{$CONFIG_ROOT_ELEMENT}->{$CONFIG_CHILD_MAXCHANNELS})) {}else{
			display_error_and_exit("Error in $filename: '$tree->{$CONFIG_ROOT_ELEMENT}->{max_channels}' is not a valid setting for $CONFIG_ROOT_ELEMENT->$CONFIG_CHILD_MAXCHANNELS (must be numeric)");
		}
		$MAX_CHANNELS = $tree->{$CONFIG_ROOT_ELEMENT}->{$CONFIG_CHILD_MAXCHANNELS};
	}

	# config->info
	if(ref($tree->{$CONFIG_ROOT_ELEMENT}->{$CONFIG_CHILD_INFO}) eq 'ARRAY'){
		display_error_and_exit("Error in $filename: $CONFIG_ROOT_ELEMENT element can't have more than one $CONFIG_CHILD_INFO element");
	} elsif($tree->{$CONFIG_ROOT_ELEMENT}->{$CONFIG_CHILD_INFO} ne undef){
		$SERVER_INFO = $tree->{$CONFIG_ROOT_ELEMENT}->{$CONFIG_CHILD_INFO};
	}

	# config->admin
	if(ref($tree->{$CONFIG_ROOT_ELEMENT}->{$CONFIG_CHILD_ADMIN}) eq 'ARRAY'){
		my @a = @{$tree->{$CONFIG_ROOT_ELEMENT}->{$CONFIG_CHILD_ADMIN}};
		foreach my $ae (@a){
			push(@ADMIN,$ae);
		}
	} elsif($tree->{$CONFIG_ROOT_ELEMENT}->{$CONFIG_CHILD_ADMIN} ne undef){
		push(@ADMIN,$tree->{$CONFIG_ROOT_ELEMENT}->{$CONFIG_CHILD_ADMIN});
	}

	# config->description
	if(ref($tree->{$CONFIG_ROOT_ELEMENT}->{$CONFIG_CHILD_DESCRIPTION}) eq 'ARRAY'){
		display_error_and_exit("Error in $filename: $CONFIG_ROOT_ELEMENT element can't have more than one $CONFIG_CHILD_DESCRIPTION element");
	} elsif($tree->{$CONFIG_ROOT_ELEMENT}->{$CONFIG_CHILD_DESCRIPTION} ne undef){
		$DESCRIPTION = $tree->{$CONFIG_ROOT_ELEMENT}->{$CONFIG_CHILD_DESCRIPTION};
	}

	# config->motd
	if(ref($tree->{$CONFIG_ROOT_ELEMENT}->{$CONFIG_CHILD_MOTD}) eq 'ARRAY'){
		display_error_and_exit("Error in $filename: $CONFIG_ROOT_ELEMENT element can't have more than one $CONFIG_CHILD_MOTD element");
	} elsif($tree->{$CONFIG_ROOT_ELEMENT}->{$CONFIG_CHILD_MOTD} ne undef){
		$MOTD_FILE = $tree->{$CONFIG_ROOT_ELEMENT}->{$CONFIG_CHILD_MOTD};
	}

}

# ===========================
# | SUPPORT SUBROUTINES END |
# ===========================
