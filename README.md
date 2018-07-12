![Raven IRCd](https://github.com/danhetrick/raven-ircd/blob/master/raven-ircd.png?raw=true)

# Raven IRCd

**Raven IRCd** (or rIRCd) is an [IRC](https://en.wikipedia.org/wiki/Internet_Relay_Chat) [server](https://en.wikipedia.org/wiki/IRCd) written in [Perl](https://en.wikipedia.org/wiki/Perl), with [POE](http://poe.perl.org/).  It is still very much a work in progress, but its base functionality is complete.  [Clients](https://en.wikipedia.org/wiki/Comparison_of_Internet_Relay_Chat_clients) can connect to it, join [channels](https://en.wikipedia.org/wiki/Internet_Relay_Chat#Channels), chat, send private messages, and do [all the things that other IRCds can do](https://en.wikipedia.org/wiki/List_of_Internet_Relay_Chat_commands).

**Raven IRCd** was written with cross-platform compatability in mind. It has been tested on Windows 10, Debian Linux, and Ubuntu Linux.

The source code for `raven-ircd.pl` is *heavily* commented. I try to explain everything the program is doing in detail, so if you want to use it as a base for your own IRCd, the **Raven IRCd** source is a good place to start.  The most complicated part of the source is the code for loading and applying configuration file settings, and thus has the most comments; it's written in pure Perl, and doesn't require POE or anything outside of the standard library (besides XML::TreePP, included with the **Raven IRCd** distribution).  If you do use **Raven IRCd** as the base for your own IRC server, remember the [license](#license), and make sure to share your additions/changes.

The latest version of **Raven IRCd** is 0.025.

# A new IRCd? Aren't there already [a](http://www.ircd-hybrid.org/) [bunch](https://www.unrealircd.org/) [of](http://www.inspircd.org/) [those](https://www.ratbox.org/) [available](http://pure-ircd.sourceforge.net/)? [You're reinventing the wheel!](https://en.wikipedia.org/wiki/Reinventing_the_wheel)

Yes, there are, and there are ones with a lot more features than **Raven IRCd**!  However, all the ones I could find for my platform (Windows 10) were fairly difficult to configure.  Most of them said in the documentation that I could expect to spend 30 or 40 minutes digging through dense configuration files *before* I could even start the server; many of these same IRCds introduced *intentional errors* in the config files so you would *have* to spend time reading them and changing settings.

This is good, I suppose, if you're planning on running an IRC server with hundreds or thousands of users, connecting to one of the big networks, like [Undernet](http://www.undernet.org/) or [EFnet](http://www.efnet.org/).  But what if you just want to run a server for five or six of your friends?  A server for your class in school, your office, or your home?

**Raven IRCd** was born when I had a need for a IRCd that was *really* easy to set up and configure quickly.  In fact, the server doesn't even need any configuration files to run successfully! At the time, I was writing an [IRC bot](https://en.wikipedia.org/wiki/IRC_bot) ([IRC-patch](https://github.com/danhetrick/ircpatch)) and I needed a server I could test the bot with.  I didn't really care how the server ran, as long as it ran like a basic IRC server.  I fought with the configuration files of [Unreal IRCd](https://www.unrealircd.org/), and after 45 minutes or so or reading and tweaking, had the server up and running. That was time that I could have spent writing and testing [my bot](https://github.com/danhetrick/ircpatch), and it was more than a little frustrating.  **Raven IRCd** was written to address this frustration; it's easy to configure and run, but if you want to delve into more custom configuration, you can do that, too.  Fast, easy, and configurable: this is an IRCd you can start using with less than 1 minute spent on configuration!

**Raven IRCd** __*is not*__ recommended for use with the big networks or with a large user base. If you want to run an IRCd that will host a lot of clients, or connect to an established IRC network, don't use **Raven IRCd**; use one of the more robust IRCds, and spend the time to configure it properly and securely. I recommend [Unreal IRCd](https://www.unrealircd.org/).

**Raven IRCd** __*is*__ recommended for testing IRC software, and small user bases.  Suggested uses would be for a LAN party, small development groups, your roommates, classmates, friends, or family.

# Requirements

[Perl](https://en.wikipedia.org/wiki/Perl), [POE](http://poe.perl.org/) (available from [CPAN](https://www.cpan.org/)), [POE::Component::Server::IRC](https://metacpan.org/pod/POE::Component::Server::IRC) (available from [CPAN](https://www.cpan.org/)), [XML::TreePP](https://metacpan.org/pod/XML::TreePP) (included with the base installation, but also from available from [CPAN](https://www.cpan.org/)).

# Files

* raven-ircd.pl
* raven-ircd.png
* LICENCE
* README.md
* lib
	* XML
		* TreePP.pm
	* RavenIRCd.pm
* settings
	* default.xml
	* operators.xml
	* auth.xml
	
------------
# Table of Contents

* [Usage](#usage)
* [Configuration](#configuration)
	* [Default Settings](#default-settings)
	* [Configuration File Format](#configuration-file-format)
		* [Default Settings](#default-settings)
		* [Restrictions](#restrictions)
		* [`import` element](#import-element)
		* [`config` element](#config-element)
			* [`config` child elements](#config-child-elements)
		* [`auth` element](#auth-element)
			* [`auth` child elements](#auth-child-elements)
		* [`operator` element](#operator-element)
			* [`operator` child elements](#auth-child-elements)
	* [Example Configuration File](#example-configuration-file)
* [License](#license)

# Usage

	perl raven-ircd.pl <CONFIGURATION FILE> -or- default

If ran with no arguments, **Raven IRCd** will load a file named `default.xml` located either in the directory where `raven-ircd.pl` is located, or in the `/settings` directory, in the same directory as `raven-ircd.pl`.  The directory where `raven-ircd.pl` is located will be called the **home directory** in the rest of this document;  the `/settings` directory located in the home directory will be called the **settings directory**.

If ran with a single filename as an argument, **Raven IRCd** will load that file as a configuration file (see [Configuration](#configuration)), and if it can't be found, will look for it first in the **home** directory, and then in the **settings** directory.  Any settings that the configuration file does *not* contain will use the default values (see [Default settings](#default-settings)).  If the file can't be found, the server will alert the user of this, but still start with all default values.

If ran with `default` as an argument, **Raven IRCd** will start *without* any configuration file; it will just use the default settings (see [Default settings](#default-settings)).

# Configuration

**Raven IRCd** configuration files are written in an [XML](https://en.wikipedia.org/wiki/XML)-like format, and have several useful features.  All server configuration is done through one or more XML configuration files; the default configuration file is named `default.xml`, and is located in the **settings** directory.

All configuration elements can be set in any configuration file loaded by **Raven IRCd**, and do not have to be in `default.xml`; passing the filename of a configuration file as the first argument to `raven-ircd.pl` will cause the program to load that file instead of `default.xml`. **Raven IRCd** can also start without a configuration file; if the configuration file does not exist or can't be found, **Raven IRCd** is loaded with default settings, opening a listening port on 6667 and allowing clients from any host to connect. To "force" **Raven IRCd** to start up without any configuration files, pass `default` as the first argument to `raven-ircd.pl`; the server won't load any configuration files, and will use the default server settings:

## Default Settings

* `auth`->`mask`
	* \*@\*
* `operator`
	* No operators are defined
* `config`->`port`
	* 6667
* `config`->`name`
	* raven.irc.server
* `config`-> `nicklength`
	* 15
* `config`->`network`
	* RavenNet
* `config`->`max_targets`
	* 4
* `config`->`max_channels`
	* 15
* `config`->`info`
	* Raven IRCd is an IRC server written in Perl and POE
* `config`->`verbose`
	* 1
* `config`->`banner`
	* 1
* `config`->`warn`
	* 1
* `config`->`admin`
	* Raven IRCd 0.025
	* The operator of this server didn't set up the admin option.
	* Sorry!
* `config`->`description`
	* Raven IRCd 0.025

In the default configuration, **Raven IRCd** ships with three configuration files:  `default.xml`, `auth.xml`, and `operators.xml`.  `default.xml` contains basic server settings, and `import`s (see [`import` element](#import-element)) `auth.xml` and `operators.xml`. `auth.xml` contains any auth entries (see [`auth` element](#auth-element)); by default, it contains only one, allowing anyone to connect.  `operators.xml` contains any operator account entries (see [`operator` element](#operator-element)); by default, it doesn't contain *any* functional operator accounts, only a commented-out one that you can uncomment and edit.

## Configuration File Format

**Raven IRCd** configuration files are written in XML.  There are four root elements in a **Raven IRCd** configuration file: [`config`](#config-element), [`import`](#import-element), [`auth`](#auth-element), and [`operator`](#operator-element).  All root elements have mandatory and/or optional child elements (with the exception of `import`, which has no child elements): `config` has _no_ manditory child elements, `auth` elements have _one_ mandatory child element ([`mask`](#mask)), and `operator` has *two* mandatory child elements ([`username`](#username) and [`password`](#password-operator)).  See [Restrictions](#restrictions) for more information.

### Restrictions

* Configuration files are only allowed to have **_one_ [`config`](#config-element) _element in each file_**; each `config` element is only allowed to have **one** of the following child elements: [`verbose`](#verbose), [`banner`](#banner), [`warn`](#warn), [`name`](#name), [`nicklength`](#nicklength), [`network`](#network), [`max_targets`](#max_targets),[`max_channels`](#max_channels), [`info`](#info), [`description`](#description).  Each `config` element is allowed to have three (3) [`admin`](#admin) child elements). Each `config` element is allowed to have multiple [`port`](#port) child elements.  All `config` child elements are optional.

* Configuration files are allowed to have **_multiple_ [`import`](#import-element) _elements_**. `import` elements have no child elements.

* Configuration files are allowed to have **_multiple_ [`auth`](#auth-element) _elements_**; each `auth` element is only allowed to have **_one_** of the following child elements: [`mask`](#mask), [`password`](#password-auth), [`spoof`](#spoof), [`no_tilde`](#no_tilde). All `auth` elements **_must have a_** `mask` **_child element_**; all other `auth` child elements are optional.

* Configuration files are allowed to have **_multiple_ [`operator`](#operator-element) _elements_**; each `operator` element is only allowed to have **_one_** of the following child elements: [`username`](#username), [`password`](#password-operator), [`ipmask`](#ipmask). All `operator` elements **_must have_** `username` **_and_** `password` **_child elements_**; `ipmask` child element is optional.

------------
### `import` element

The `import` element is used to load configuration data from external files, much like C's `#include` preprocesser directive.  **Raven IRCd** will look for `import`'ed files first in the **home** directory, then in the **settings** directory.  The `import` element has no children elements.  Multiple `import` elements can be set, and they can be set in any configuration file loaded;  thus, `import`'ed files can contain `import` elements, which can *also* contain `import` elements, and so on.

-----------
### `config` element

The `config` element is where all the main server settings are.  They are all optional; the server will use a listening port of `6667` and let anyone connect to it.  `config` has a number of children elements, all optional.  Here's an example of a basic `config` entry, with all default settings:

	<config>
		<verbose>1</verbose>
		<banner>1</banner>
		<warn>1</warn>
		<port>6667</port>
		<name>raven.irc.server</name>
		<nicklength>15</nicklength>
		<network>RavenNet</network>
		<max_targets>4</max_targets>
		<max_channels>15</max_channels>
		<info>Raven IRCd</info>
		<admin>Raven IRCd 0.025</admin>
		<admin>The operator of this server didn't set up the admin option.</admin>
		<admin>Sorry!</admin>
		<description>Raven IRCd 0.025</description>
	</config>

Multiple `config` elements can be set (although they must be in separate files; see [Restrictions](#restrictions)), though it may confuse the server (and you!). Configuration files are processed in order;  for example, if a file is imported with the `import` element, it will be loaded before any other elements following the `import` element are loaded.  As an example, let's say that you have two configuration files that you want to use, `mysettings.xml` and `othersettings.xml`.

	<!-- mysettings.xml -->
	<?xml version="1.0" encoding="UTF-8"?>
	<config>
		<port>6667</port>
		<nicklength>1000000</nicklength>
		<network>ScoobyDooNet</network>
	</config>

	<import>othersettings.xml</import>

As you can see, this file sets the listening port to 6667, the nick length to a generous 1,000,000 characters, the network name to "ScoobyDooNet", and `import`s another configuration file, "othersettings.xml":

	<!-- othersettings.xml -->
	<?xml version="1.0" encoding="UTF-8"?>
	<config>
		<nicklength>2</nicklength>
	</config>

When all the configuration files are loaded, our users lose the generous nick length of 1,000,000 characters, and now are left with a paltry 2 character limit for their nickname.  Why?  Even though `mysettings.xml` was loaded *first*, `othersettings.xml` was loaded after it, and changed the nick length from 1,000,000 to 2.  If we had `import`'ed `othersettings.xml` before we set our config element, the nick length of 1,000,000 would still be set (because the `nicklength` setting in `mysettings.xml` was loaded *after* the `nicklength` setting in `othersettings.xml`).

The only exception to this rule is the [`port` child element](#port);  it doesn't overwrite `port` elements in any other configuration file.  New `port` elements just add new listening ports without removing previously set ports.

#### `config` child elements

* [verbose](#verbose)**\***
* [port](#port)**\***
* [name](#name)**\***
* [nicklength](#nicklength)**\***
* [network](#network)**\***
* [max_targets](#max_targets)**\***
* [max_channels](#max_channels)**\***
* [info](#info)**\***
* [banner](#banner)**\***
* [warn](#warn)**\***
* [admin](#admin)**\***
* [description](#description)**\***

Elements marked with an asterix (**\***) are optional.

------------
##### `verbose`

Set this element to 1 if you want to turn on verbosity;  set it to 0 to turn it off.  If `verbose` is turned on, various data will be printed to the console during runtime.  Warnings will *always* be displayed if `verbose` is turned on.

------------
##### `port`

Sets the [port](https://en.wikipedia.org/wiki/Port_(computer_networking)) that **Raven IRCd** will listen on.  Multiple `port` elements can exist; each one will spawn a listener on the given port.

------------
##### `name`

Sets the server's name.

------------
##### `nicklength`

Sets the maximum number of characters that can be used in a client's nick.

------------
##### `network`

Sets the name of the network **Raven IRCd** will use.

------------
##### `max_targets`

Sets the maximum number of clients a user can send a private message to in one operation.

------------
##### `max_channels`

Sets the maximum number of channels a client can join.

------------
##### `info`

Sets the text displayed with the `info` IRC command.

------------
##### `banner`

Turns banner display on start up on (1) or off (0).

------------
##### `warn`

Turns warnings on (1) or off (1). If `warn` us turned on, warnings will *always* be displayed, even if `verbose` is turned off.

------------
##### `admin`

Sets the text returned by the `/admin` IRC command. Each `admin` element adds one line to the admin text, with a maximum of three lines allowed. If more than three lines are added (that is, if there's more than three `admin` elements), only the first three `admin` elements are used, and the user is warned. If only one or two `admin` elements are set, the other line(s) are set to be blank. If no `admin` elements are set, the default values are used (see [Default settings](#default-settings)).

------------
##### `description`

Sets the server's description text.

------------
#### `auth` element

Here's where we set who's allowed to connect to the IRC server.  You can set what hosts clients must be on to connect, set passwords for certain hosts, whether to spoof client hostnames, and whether or not to remove the tilde (~) from hostnames.  The only required child element is `mask`.  Here's an example `auth` entry:

	<auth>
		<mask>*@*</mask>
		<password>changeme</password>
		<spoof>google.com</spoof>
		<no_tilde>1</no_tilde>
	</auth>

This example will let anyone connect to the server, require a password ("changeme"), spoof all clients' host to "google.com", and remove the tilde from reported hostmasks.  Multiple `auth` elements can be set.

If no `auth` element is set, **Raven IRCd** will assume that anyone is allowed to connect;  in effect, it will be as if an `auth` element *was* set, with the only child element `mask` set to `*@*`.

#### `auth` child elements

* [mask](#mask)
* [password](#password-auth)**\***
* [spoof](#spoof)**\***
* [no_tilde](#no_tilde)**\***

Elements marked with an asterix (**\***) are optional.

------------
##### `mask`

Sets who's allowed to connect to the server.  `*@*` (the default) will let anyone connect.  For example, to let only clients on the `google.com` host connect, you would set `mask` to `*@google.com`.  Required child element.

------------
##### `password` (auth)

Sets the password required to connect with the given `mask`.  Not a required child element.

------------
##### `spoof`

All users connected with the given `mask` will have their host spoofed with the host noted here.  For example, to make it appear if all clients on `@*@` were connected from `facebook.com`, you'd set `spoof` to `facebook.com`.  Not a required child element.

------------
##### `no_tilde`

Removes the tilde (~) from reported hostmaks.  Set to 1 to remove the tilde, and set to 0 to leave the tilde in place.  Not a required child element.

------------
### `operator` element

The `operator` element is where clients can be granted IRC operator status.  There are two required children elements, `username` and `password`, and one optional child, `ipmask`.  Here's an example entry that creates a new operator with the username `bob`, password `changeme`, and ipmask `192.168.0.*`:

	<operator>
		<username>bob</username>
		<password>changeme</password>
		<ipmask>192.168.0.*</ipmask>
	</operator>

In this example, only clients connecting from an IP address that starts with "192.168.0." would be allowed to log in to this operator account.  Multiple `operator` elements can be set.

#### `operator` child elements

* [username](#username)
* [password](#password-operator)
* [ipmask](#ipmask)**\***

Elements marked with an asterix (**\***) are optional.

------------
##### `username`

Sets the username of the operator, required for login.  Required child element.

------------
##### `password` (operator)

Sets the password for the operator, required for login.  Required child element.

------------
##### `ipmask`

Sets what IP addresses are allowed to use this operator account.  Not a required child element. Use \*\ for a multiple character wild card, or ? for a single character wild card.  For example, if you're on a LAN with all internal IP addresses starting with "192.168.1", to allow only people on your LAN to become operators, use an ipmask of "192.168.1.\*".

------------
## Example Configuration File

Here's an example configuration file.  It'll set up listening ports on ports 6667-6669, allow anyone to connect (spoofing their host to appear as if they are connecting from `facebook.com`), and create an operator with the username `oracle` and the password `thematrix`.  The server's name with be "example.raven.setup" on the "OscarNet" network, and will allow clients to connect to 50 channels and a time, and let them use only 8 characters in their nick:

	<?xml version="1.0" encoding="UTF-8"?>

	<config>
		<port>6667</port>
		<port>6668</port>
		<port>6669</port>
		<name>example.raven.setup</name>
		<nicklength>8</nicklength>
		<network>OscarNet</network>
		<max_channels>50</max_channels>
	</config>

	<auth>
		<mask>*@*</mask>
		<spoof>facebook.com</spoof>
	</auth>

	<operator>
		<username>oracle</username>
		<password>thematrix</password>
	</operator>

If saved to a file named `oscarnet.xml`, **Raven IRCd** can load the configuration file and run it like so:

	user@localhost:$ perl raven-ircd.pl oscarnet.xml
	 _____                         _____ _____   _____    _
	|  __ \                       |_   _|  __ \ / ____|  | |
	| |__) |__ ___   _____ _ __     | | | |__) | |     __| |
	|  _  // _` \ \ / / _ \ '_ \    | | |  _  /| |    / _` |
	| | \ \ (_| |\ V /  __/ | | |  _| |_| | \ \| |___| (_| |
	|_|  \_\__,_| \_/ \___|_| |_| |_____|_|  \_\\_____\__,_|
	----------------------------------------Raven IRCd 0.025
	-----Raven IRCd is an IRC server written in Perl and POE
	----------------https://github.com/danhetrick/raven-ircd

	[4:23:40 6/11/2018] Loaded configuration file 'oscarnet.xml'

**Raven IRCd** is up and running!  Connect to it on port 6667, 6668, or 6669 and chat away!

------------
# License

Raven IRCd - An open-source IRC server written in Perl

Copyright (C) 2018  Daniel Hetrick

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
