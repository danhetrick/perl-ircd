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

package RavenIRCd;

use strict;
use POE::Component::Server::IRC::Plugin qw(:ALL);
use base qw(POE::Component::Server::IRC);

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

    return PCSI_EAT_NONE;
}

1;
