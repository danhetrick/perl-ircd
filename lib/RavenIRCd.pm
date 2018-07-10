# ============
# RavenIRCd.pm
# ============

# Inherits from POE::Component::Server::IRC

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
