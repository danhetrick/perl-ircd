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

package Raven::Bot;

use strict;
use POE::Component::Server::IRC::Plugin qw(:ALL);
use base qw(POE::Component::Server::IRC::Plugin::OperServ);

my $BOT_NAME = "OperServ";
my $BOT_IRCNAME = 'The OperServ bot';

sub set_opserv_name {
	$BOT_NAME = shift;
}

sub set_opserv_ircname {
	$BOT_IRCNAME = shift;
}

sub PCSI_register {
    my ($self, $ircd) = splice @_, 0, 2;

    $ircd->plugin_register($self, 'SERVER', qw(daemon_privmsg daemon_join));
    $ircd->yield(
        'add_spoofed_nick',
        {
            nick    => $BOT_NAME,
            umode   => 'Doi',
            ircname => $BOT_IRCNAME,
        },
    );
    return 1;
}

sub IRCD_daemon_privmsg {
    my ($self, $ircd) = splice @_, 0, 2;
    my $nick = (split /!/, ${ $_[0] })[0];

    return PCSI_EAT_NONE if !$ircd->state_user_is_operator($nick);
    my $request = ${ $_[2] };

    SWITCH: {
        if (my ($chan) = $request =~ /^clear\s+(#.+)\s*$/i) {
            last SWITCH if !$ircd->state_chan_exists($chan);
            $ircd->yield('daemon_cmd_sjoin', $BOT_NAME, $chan);
            last SWITCH;
        }
        if (my ($chan) = $request =~ /^join\s+(#.+)\s*$/i) {
            last SWITCH if !$ircd->state_chan_exists($chan);
            $ircd->yield('daemon_cmd_join', $BOT_NAME, $chan);
            last SWITCH;
        }
        if (my ($chan) = $request =~ /^part\s+(#.+)\s*$/i) {
            last SWITCH unless $ircd->state_chan_exists($chan);
            $ircd->yield('daemon_cmd_part', $BOT_NAME, $chan);
            last SWITCH;
        }
        if (my ($chan, $mode) = $request =~ /^mode\s+(#.+)\s+(.+)\s*$/i) {
            last SWITCH if !$ircd->state_chan_exists($chan);
            $ircd->yield('daemon_cmd_mode', $BOT_NAME, $chan, $mode);
            last SWITCH;
        }
        if (my ($chan, $target) = $request =~ /^op\s+(#.+)\s+(.+)\s*$/i) {
            last SWITCH unless $ircd->state_chan_exists($chan);
            $ircd->daemon_server_mode($chan, '+o', $target);
        }
    }

    return PCSI_EAT_NONE;
}

sub IRCD_daemon_join {
    my ($self, $ircd) = splice @_, 0, 2;
    my $nick = (split /!/, ${ $_[0] })[0];
    if (!$ircd->state_user_is_operator($nick) || $nick eq $BOT_NAME) {
        return PCSI_EAT_NONE;
    }
    my $channel = ${ $_[1] };
    return PCSI_EAT_NONE if $ircd->state_is_chan_op($nick, $channel);
    $ircd->daemon_server_mode($channel, '+o', $nick);
    return PCSI_EAT_NONE;
}


1;
