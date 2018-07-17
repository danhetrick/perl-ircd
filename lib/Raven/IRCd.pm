#
# ██████╗  █████╗ ██╗   ██╗███████╗███╗   ██╗   I
# ██╔══██╗██╔══██╗██║   ██║██╔════╝████╗  ██║   R
# ██████╔╝███████║██║   ██║█████╗  ██╔██╗ ██║   C
# ██╔══██╗██╔══██║╚██╗ ██╔╝██╔══╝  ██║╚██╗██║   d
# ██║  ██║██║  ██║ ╚████╔╝ ███████╗██║ ╚████║   *
# ╚═╝  ╚═╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝╚═╝  ╚═══╝   *
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

package Raven::IRCd;

use strict;
use POE::Component::Server::IRC::Plugin qw(:ALL);
use base qw(POE::Component::Server::IRC);

# =================
# | GLOBALS BEGIN |
# =================

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~
# | OPERSERV SETTINGS BEGIN |
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~

# -----------
# | SCALARS |
# -----------

my $OPERSERV                    = 0;            # Is OperServ on (1)?
my $OPERSERV_NAME               = "OperServ";   # OperServ's nick
my $OPERSERV_CHANNEL_CONTROL    = 0;            # Is channel control mode on (1)?

# ----------
# | ARRAYS |
# ----------

my @CHANNELS                    = ();           # Channels OperServ is in

# ~~~~~~~~~~~~~~~~~~~~~~~~~
# | OPERSERV SETTINGS END |
# ~~~~~~~~~~~~~~~~~~~~~~~~~

# ===============
# | GLOBALS END |
# ===============

# ==================
# Overloaded Methods
# ==================

sub _load_our_plugins {
    my $self = shift;
    $self->SUPER::_load_our_plugins();
    # $self->yield(
    #     'add_spoofed_nick',
    #     {
    #         nick    => $operator_name,
    #         umode   => "Doi",
    #         ircname => $operator_name
    #     }
    # );
}

# ======
# Events
# ======

sub IRCD_daemon_server {
    my ( $self, $ircd ) = splice @_, 0, 2;
    my $name        = ${ $_[0] };
    my $introducer  = ${ $_[1] };
    my $hopcount    = ${ $_[2] };
    my $description = ${ $_[3] };

    return PCSI_EAT_NONE;
}

sub IRCD_daemon_nick {
    my ( $self, $ircd ) = splice @_, 0, 2;
    if ( $#_ == 7 ) {
        my $nick       = $_[0];
        my $hop_count  = $_[1];
        my $timestamp  = $_[2];
        my $umode      = $_[3];
        my $ident      = $_[4];
        my $hostname   = $_[5];
        my $servername = $_[6];
        my $realname   = $_[7];

    }
    elsif ( $#_ == 1 ) {
        my $nick     = ( split /!/, ${ $_[0] } )[0];
        my $hostmask = ( split /!/, ${ $_[0] } )[1];
        my $newnick  = $_[1];

    }

    return PCSI_EAT_NONE;
}

sub IRCD_daemon_quit {
    my ( $self, $ircd ) = splice @_, 0, 2;
    my $nick     = ( split /!/, ${ $_[0] } )[0];
    my $hostmask = ( split /!/, ${ $_[0] } )[1];
    my $quitmsg  = "$nick";
    if ( $#_ >= 2 ) { $quitmsg = ${ $_[2] }; }

    return PCSI_EAT_NONE;
}

sub IRCD_daemon_notice {
    my ( $self, $ircd ) = splice @_, 0, 2;
    my $nick     = ( split /!/, ${ $_[0] } )[0];
    my $hostmask = ( split /!/, ${ $_[0] } )[1];
    my $request  = ${ $_[2] };

    return PCSI_EAT_NONE;
}

sub IRCD_daemon_privmsg {
    my ( $self, $ircd ) = splice @_, 0, 2;
    my $nick     = ( split /!/, ${ $_[0] } )[0];
    my $hostmask = ( split /!/, ${ $_[0] } )[1];
    my $request  = ${ $_[2] };

    return PCSI_EAT_NONE;
}

sub IRCD_daemon_join {
    my ( $self, $ircd ) = splice @_, 0, 2;
    my $nick     = ( split /!/, ${ $_[0] } )[0];
    my $hostmask = ( split /!/, ${ $_[0] } )[1];
    my $channel  = ${ $_[1] };

    # If OperServ is turned on...
    if($OPERSERV==1){
        # And OperServ isn't in the channel being joined...
        if(in_channel($channel)==0){
            # And OperServ channel control mode is on...
            if($OPERSERV_CHANNEL_CONTROL==1){
                # Add the channel to the list of channels OperServ is in
                add_channel($channel);
                # "Super join" the channel, claiming ops
                $ircd->yield('daemon_cmd_sjoin', $OPERSERV_NAME, $channel);
            }
        }
    }

    return PCSI_EAT_NONE;
}

sub IRCD_daemon_umode {
    my ( $self, $ircd ) = splice @_, 0, 2;
    my $nick     = ( split /!/, ${ $_[0] } )[0];
    my $hostmask = ( split /!/, ${ $_[0] } )[1];
    my $umode    = ${ $_[1] };

    return PCSI_EAT_NONE;
}

sub IRCD_daemon_part {
    my ( $self, $ircd ) = splice @_, 0, 2;
    my $nick     = ( split /!/, ${ $_[0] } )[0];
    my $hostmask = ( split /!/, ${ $_[0] } )[1];
    my $channel  = ${ $_[1] };
    my $partmsg  = ${ $_[2] };

    # If OperServ is turned on...
    if($OPERSERV==1){
        # And OperServ is in this channel...
        if(in_channel($channel)==1){
            # And the user parting is OperServ...
            if($nick eq $OPERSERV_NAME){
                    # Remove the channel from OperServ's list
                    remove_channel($channel);
            }
        }
     }


    return PCSI_EAT_NONE;
}

# =============================
# | SUPPORT SUBROUTINES BEGIN |
# =============================

# enable_operserv()
# in_channel()
# remove_channel()
# add_channel()

# enable_operserv()
# Arguments: 2 (scalar [OperServ's nick], scalar [channel control on/off])
# Returns: Nothing
# Description: Enables OperServ and sets channel control mode
sub enable_operserv {
    my $n = shift;
    my $c = shift;
    $OPERSERV = 1;
    $OPERSERV_NAME = $n;
    $OPERSERV_CHANNEL_CONTROL = $c;
}

# in_channel()
# Arguments: 1 (scalar [channel])
# Returns: 1 or 0
# Description: Returns 1 if OperServ is in the channel, 0 if not.
sub in_channel {
    my $chan = shift;
    foreach my $c (@CHANNELS){
        if($c eq $chan){
            return 1;
        }
    }
    return 0;
}

# remove_channel()
# Arguments: 1 (scalar [channel])
# Returns: Nothing
# Description: Removes a channel from OperServ's list
sub remove_channel {
    my $chan = shift;
    my @new = ();
    foreach my $c (@CHANNELS){
        if($c eq $chan) { next; }
        push(@new,$c);
    }
    @CHANNELS = @new;
}

# add_channel()
# Arguments: 1 (scalar [channel])
# Returns: Nothing
# Description: Adds a channel to OperServ's list
sub add_channel {
    my $chan = shift;
    foreach my $c (@CHANNELS){
        if($c eq $chan){
            return;
        }
    }
    push(@CHANNELS,$chan);
}

# ===========================
# | SUPPORT SUBROUTINES END |
# ===========================

1;
