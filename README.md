![Raven IRCd](https://github.com/danhetrick/raven-ircd/blob/master/raven_ircd.png?raw=true)

# Raven IRCd

**Raven IRCd** (or rIRCd) is an [IRC](https://en.wikipedia.org/wiki/Internet_Relay_Chat) server written in [Perl](https://en.wikipedia.org/wiki/Perl), with [POE](http://poe.perl.org/).  It is still very much a work in progress, but its base functionality is complete.  [Clients](https://en.wikipedia.org/wiki/Comparison_of_Internet_Relay_Chat_clients) can connect to it, join [channels](https://en.wikipedia.org/wiki/Internet_Relay_Chat#Channels), chat, send private messages, and do [all the things that other IRCds can do](https://en.wikipedia.org/wiki/List_of_Internet_Relay_Chat_commands).

**Raven IRCd** was written with cross-platform compatability in mind. It has been tested on Windows 10, Debian Linux, and Ubuntu Linux.

The source code for `raven-ircd.pl` is *heavily* commented. I try to explain everything the program is doing in detail, so if you want to use it as a base for your own IRCd, the **Raven IRCd** source is a good place to start.  The most complicated part of the source is the code for loading and applying configuration file settings, and thus has the most comments; it's written in pure Perl, and doesn't require POE or anything outside of the standard library (besides XML::TreePP, included with the **Raven IRCd** distribution).  If you do use **Raven IRCd** as the base for your own IRC server, remember the [license](#license), and make sure to share your additions/changes.

# A new IRCd? Aren't there already a bunch of those available?

Yes, there are, and there are ones with a lot more features than **Raven IRCd**!  However, all the ones I could find for my platform (Windows 10) were fairly difficult to configure.  Most of them said in the documentation that I could expect to spend 30 or 40 minutes digging through dense configuration files *before* I could even start the server; many of these same IRCds introduced *intentional errors* in the config files so you would *have* to spend time reading them and changing settings.

This is good, I suppose, if you're planning on running an IRC server with hundreds or thousands of users, connecting to one of the big networks, like [Undernet](http://www.undernet.org/) or [EFnet](http://www.efnet.org/).  But what if you just want to run a server for five or six of your friends?  A server for your class in school, your office, or your home?

**Raven IRCd** was born when I had a need for a IRCd that was *really* easy to set up and configure quickly.  In fact, the server doesn't even need any configuration files to run successfully! At the time, I was writing an [IRC bot](https://en.wikipedia.org/wiki/IRC_bot) ([IRC-patch](https://github.com/danhetrick/ircpatch)) and I needed a server I could test the bot with.  I didn't really care how the server ran, as long as it ran like a basic IRC server.  I fought with the configuration files of [Unreal IRCd](https://www.unrealircd.org/), and after 45 minutes or so or reading and tweaking, had the server up and running. That was time that I could have spent writing and testing [my bot](https://github.com/danhetrick/ircpatch), and it was more than a little frustrating.  **Raven IRCd** was written to address this frustration; it's easy to configure and run, but if you want to delve into more custom configuration, you can do that, too.  Fast, easy, and configurable: this is an IRCd you can start using with less than 1 minute spent on configuration!

**Raven IRCd** __*is not*__ recommended for use with the big networks or with a large user base. If you want to run an IRCd that will host a lot of clients, or connect to an established IRC network, don't use **Raven IRCd**; use one of the more robust IRCds, and spend the time to configure it properly and securely. I recommend [Unreal IRCd](https://www.unrealircd.org/).

**Raven IRCd** __*is*__ recommended for testing IRC software, and small user bases.  Suggested uses would be for a LAN party, small development groups, your roommates, classmates, friends, or family.

# Requirements

[Perl](https://en.wikipedia.org/wiki/Perl), [POE](http://poe.perl.org/), [POE::Component::Server::IRC](https://metacpan.org/pod/POE::Component::Server::IRC).

# Files

* raven-ircd.pl
* raven-ircd.png
* LICENCE
* README.md
* lib
	* XML
		* TreePP.pm
	* RavenIRCd.pm
* config
	* ircd.xml
	* operators.xml
	* auth.xml

------------
# Table of Contents

* [Usage](#usage)
* [Configuration](#configuration)
	* [Default settings](#default-settings)
	* [Configuration file XML elements](#configuration-file-XML-elements)
		* [`import` element](#import-element)
		* [`config` element](#config-element)
			* [ `Config` child elements](#config-child-elements)
				* [verbose](#verbose)
				* [port](#port)
				* [name](#name)
				* [nicklength](#nicklength)
				* [network](#network)
				* [max_targets](#max_targets)
				* [max_channels](#max_channels)
				* [info](#info)
		* [`auth` element](#auth-element)
			* [`auth` child elements](#auth-child-elements)
				* [mask](#mask)
				* [password](#password)
				* [spoof](#spoof)
				* [no_tilde](#no_tilde)
		* [`operator` element](#operator-element)
			* [`operator` child elements](#auth-child-elements)
				* [username](#username)
				* [password](#password)
				* [ipmask](#ipmask)
	* [Example configuration file](#example-configuration-file)
* [License](#license)

# Usage

	perl raven-ircd.pl <CONFIGURATION FILE>

By default, **Raven IRCd** will load a file named `ircd.xml` located either in the directory where `raven-ircd.pl` is located, or in the `/config` directory, in the same directory as `raven-ircd.pl`.  The directory where `raven-ircd.pl` is located will be called the **home directory** in the rest of this document;  the `/config` directory located in the home directory will be called the **config directory**. **Raven IRCd** doesn't *require* a configuration file; it will just use the default settings (see [Default settings](#default-settings)) if one isn't supplied.

# Configuration

**Raven IRCd** configuration files are written in [XML](https://en.wikipedia.org/wiki/XML), and have several useful features.  All server configuration is done through one or more XML configuration files; the default configuration file is named `ircd.xml`, and is located in the **config** directory.

All configuration elements can be set in any configuration file loaded by **Raven IRCd**, and do not have to be in `ircd.xml`. **Raven IRCd** can also start without a configuration file; if the configuration file does not exist or can't be found, **Raven IRCd** is loaded with default settings, opening a listening port on 6667 and allowing clients from any host to connect.

## Default settings

* `auth`
	* *@*
* `operator`
	* No operators
* `port`
	* 6667
* `name`
	* raven.irc.server
* `nicklength`
	* 15
* `network`
	* RavenNet
* `max_targets`
	* 4
* `max_channels`
	* 15
* `info`
	* An IRC server written in Perl and POE
* `verbose`
	* 1

## Configuration file XML elements

### `import` element

The `import` element is used to load configuration data from external files, much like C's `#include` preprocesser directive.  **Raven IRCd** will look for `import`'ed files first in the **home** directory, then in the **config** directory.  The `import` element has no children elements.  Multiple `import` elements can be set, and they can be set in any configuration file loaded;  thus, `import`'ed files can contain `import` elements, which can *also* contain `import` elements, and so on.

------------
### `config` element

The `config` element is where all the main server settings are.  They are all optional; the server will use a listening port of `6667` and let anyone connect to it.  `config` has a number of children elements, all optional.  Here's an example of a basic `config` entry, with all default settings:

	<config>
		<verbose>1</verbose>
		<port>6667</port>
		<name>raven.irc.server</name>
		<nicklength>15</nicklength>
		<network>RavenNet</network>
		<max_targets>4</max_targets>
		<max_channels>15</max_channels>
		<info>Raven IRCd</info>
	</config>

In the default set of configuration files, `config`, `operator`, and `auth` elements are contained in seperate files;  `config` is in the default config file, `ircd.xml`, and the two other elements are `import`'ed (in `operators.xml` and `auth.xml`, respectively).

Multiple `config` elements can be set, though it may confuse the server (and you!). Configuration files are processed in order;  for example, if a file is imported with the `import` element, it will be loaded before any other elements following the `import` element are loaded.  As an example, let's say that you have two configuration files that you want to use, `mysettings.xml` and `othersettings.xml`.

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

------------
##### `verbose`

Set this element to 1 if you want to turn on verbosity;  set it to 0 to turn it off.  If `verbose` is turned on, various data will be printed to the console during runtime.

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

------------
##### `mask`

Sets who's allowed to connect to the server.  `*@*` (the default) will let anyone connect.  For example, to let only clients on the `google.com` host connect, you would set `mask` to `*@google.com`.  Required.

------------
##### `password`

Sets the password required to connect with the given `mask`.  Not required.

------------
##### `spoof`

All users connected with the given `mask` will have their host spoofed with the host noted here.  For example, to make it appear if all clients on `@*@` were connected from `facebook.com`, you'd set `spoof` to `facebook.com`.  Not required.

------------
##### `no_tilde`

Removes the tilde (~) from reported hostmaks.  Set to 1 to remove the tilde, and set to 0 to leave the tilde in place.  Not required.

------------
### `operator` element

The `operator` element is where clients can be granted IRC operator status.  There are two required children elements, `username` and `password`, and one optional child, `ipmask`.  Here's an example entry that creates a new operator with the username `bob`, password `changeme`, and ipmask `*@google.com`:

	<operator>
		<username>bob</username>
		<password>changeme</password>
		<ipmask>*@google.com</ipmask>
	</operator>

In this example, only clients connecting from the host `google.com` would be allowed to log in.  Multiple `operator` elements can be set.

#### `operator` child elements

------------
##### `username`

Sets the username of the operator, required for login.  Required child element.

------------
##### `password`

Sets the password for the operator, required for login.  Required child element.

------------
##### `ipmask`

Sets what hosts are allowed to use this operator account.  Not a required child element.

------------
## Example configuration file

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
	----------------------------------------Raven IRCd 0.021
	-------------------An IRC server written in Perl and POE
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
