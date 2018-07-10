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

use strict;
use warnings;
use POE qw(Component::Server::IRC);
use FindBin qw($RealBin);
use File::Spec;

# Local modules
use lib File::Spec->catfile($RealBin,'lib');
use XML::TreePP;
use RavenIRCd;

#use Data::Dumper;

# ===============
# | MODULES END |
# ===============

# =================
# | GLOBALS BEGIN |
# =================

# -------------
# | CONSTANTS |
# -------------

use constant AUTH_MASK			=> 0;
use constant AUTH_PASSWORD		=> 1;
use constant AUTH_SPOOF			=> 2;
use constant AUTH_TILDE			=> 3;

use constant OPERATOR_USERNAME	=> 0;
use constant OPERATOR_PASSWORD	=> 1;
use constant OPERATOR_IPMASK	=> 2;

# -----------
# | SCALARS |
# -----------

# Default server settings
my $SERVER_NAME		= "raven.irc.server";
my $NICKNAME_LENGTH	= 15;
my $SERVER_NETWORK	= "RavenNet";
my $MAX_TARGETS		= 4;
my $MAX_CHANNELS	= 15;
my $SERVER_INFO		= "Raven IRCd";
my $DEFAULT_PORT	= 6667;
my $DEFAULT_AUTH	= '*@*';
my $VERBOSE			= 1;

# Configuration file settings
my $CONFIGURATION_FILE				= "xxircd.xml";
my $CONFIGURATION_DIRECTORY_NAME	= "config";

# ----------
# | ARRAYS |
# ----------

my @LISTENER_PORTS	= ();
my @AUTHS			= ();
my @OPERATORS		= ();

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
# use default settings and warn the user.
if($found_configuration_file){
	load_xml_configuration_file($found_configuration_file);
	verbose(logo());
	verbose("Using configuration file '$found_configuration_file'");
} else {
	verbose(logo());
	display_warning("No configuration file found; starting server with default settings");
}

# Set our server configuration 
my %config = (
    servername	=> $SERVER_NAME, 
    nicklen		=> $NICKNAME_LENGTH,
    network		=> $SERVER_NETWORK,
    maxtargets	=> $MAX_TARGETS,
    maxchannels	=> $MAX_CHANNELS,
    info		=> $SERVER_INFO
);

# Spawn our RavenIRCd instance
my $pocosi = RavenIRCd->spawn( config => \%config );

# Create our POE session
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

# ======================
# | SUPPORT CODE BEGIN |
# ======================

# ----------------------
# | POE Event Handlers |
# ----------------------

#	_start()

# --------------------
# | User Interaction |
# --------------------

#	verbose()
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
 
sub _start {
    my ($kernel, $heap) = @_[KERNEL, HEAP];
 
 	# Make sure we get all events
    $heap->{ircd}->yield('register', 'all');

    # Add authorized connections
    if(scalar @AUTHS >=1){
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
    		display_warning('Auth element not found. Using *@* as the auth');
    		$heap->{ircd}->add_auth(
	        	mask		=> '*@*',
    		); 
    }
 
    # Start up listening port(s)
    if(scalar @LISTENER_PORTS >=1){
	    foreach my $p (@LISTENER_PORTS){
	    	$heap->{ircd}->add_listener(port => $p);
	    }
	} else {
		display_warning('Port element not found. Using 6667 as the server port');
	}
 
    # Add IRC operators
    if(scalar @OPERATORS>=1){
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
		display_warning('Operator element not found. Server will start without operators');
	}


}

# --------------------
# | User Interaction |
# --------------------

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
	print "ERROR: $msg\n";
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

# -------------------------------
# | Configuration File Handling |
# -------------------------------

# find_configuration_file()
# Arguments: 1 (scalar, filename)
# Returns: Scalar (filename)
# Description: Looks for a given configuration file in the several directories
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
			$i = find_configuration_file($i);
			if(!$i){
				display_error_and_exit("Configuration file '$filename' not found");
			}
			load_xml_configuration_file($i);
		}
	} elsif($tree->{import}){
		my $f = find_configuration_file($tree->{import});
		if(!$f){
			display_error_and_exit("Configuration file '$filename' not found");
		}
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

# ====================
# | SUPPORT CODE END |
# ====================
