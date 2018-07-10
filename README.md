![Raven IRCd](https://github.com/danhetrick/raven-ircd/blob/master/raven_ircd.png?raw=true)

# Raven IRCd

Raven IRCd (or rIRCd) is an IRC server written in Perl, with POE.  It is still very much a work in progress, but its base functionality is complete.  Clients can connect to it, join channels, and do all the things that other IRCds can do.

# Table of Contents

* [Usage](#usage)
* [Configuration](#configuration)
	* [import element](#import-element)
	* [config element](#config-element)
		* [verbose](#verbose)
		* [port](#port)
		* [name](#name)
		* [nicklength](#nicklength)
		* [network](#network)
		* [max_targets](#max_targets)
		* [max_channels](#max_channels)
		* [info](#info)
	* [auth element](#auth-element)
		* [mask](#mask)
		* [password](#password)
		* [spoof](#spoof)
		* [no_tilde](#no_tilde)

# Usage

	perl rircd.pl <CONFIGURATION FILE>

By default, Raven IRCd will load a file named `ircd.xml` located either in the directory where `rircd.pl` is located, or in the `config/` directory, in the same directory as `rircd.pl`.  The directory where `rircd.pl` is located will be called the **home directory** in the rest of this document;  the `/config` directory located in the home directory will be called the **config directory**.

# Configuration

Raven IRCd configuration files are written in XML, and have several useful features.

## `import` element

The `import` element is used to load configuration data from external files, much like C's `#include` preprocesser directive.  Raven IRCd will look for `import`'ed files first in the home directory, then in the config directory.  The `import` element has no children elements.

## `config` element

The `config` element is where all the main server settings are.  They are all optional; the server will use a listening port of `6667` and let anyone connect to it.  `config` has a number of children elements.  Here's an example of a basic `config` entry, with all default settings:

	<?xml version="1.0" encoding="UTF-8"?>
	<config>
		<verbose>1</verbose>
		<port>6667</port>
		<name>Perl.IRC.Server</name>
		<nicklength>15</nicklength>
		<network>PerlNet</network>
		<max_targets>4</max_targets>
		<max_channels>15</max_channels>
		<info>My IRC Server</info>
	</config>

### `verbose`

Set this element to 1 if you want to turn on verbosity;  set it to 0 to turn it off.  If `verbose` is turned on, various data will be printed to the console during runtime.

### `port`

Sets the port that Raven IRCd will listen on.  Multiple `port` elements can exist; each one will spawn a listener on the given port.

### `name`

Sets the server's name.

### `nicklength`

Sets the maximum number of characters that can be used in a client's nick.

### `network`

Sets the name of the network Raven IRCd will use.

### `max_targets`

Sets the maximum number of clients a user can send a private message to in one operation.

### `max_channels`

Sets the maximum number of channels a client can join.

### `info`

Sets the text displayed with the `info` IRC command.

## `auth` element

Here's where we set who's allowed to connect to the IRC server.  You can set what hosts clients must be on to connect, set passwords for certain hosts, whether to spoof client hostnames, and whether or not to remove the tilde (~) from hostnames.  The only required child element is `mask`.  Here's an example `auth` entry:

	<?xml version="1.0" encoding="UTF-8"?>
	<auth>
		<mask>*@*</mask>
		<password>changeme</password>
		<spoof>google.com</spoof>
		<no_tilde>1</no_tilde>
	</auth>

This example will let anyone connect to the server, require a password ("changeme"), spoof all clients' host to "google.com", and remove the tilde from reported hostmasks.  Multiple `auth` elements can be set.

### `mask`

Sets who's allowed to connect to the server.  `*@*` (the default) will let anyone connect.  For example, to let only clients on the `google.com` host connect, you would set `mask` to `*@google.com`.

### `password`

Sets the password required to connect with the given `mask`.  Not required.

### `spoof`

All users connected with the given `mask` will have their host spoofed with the host noted here.  For example, to make it appear if all clients on `@*@` were connected from `facebook.com`, you'd set `spoof` to `facebook.com`.

### `no_tilde`

Removes the tilde (~) from reported hostmaks.

## `operator` element

The `operator` element is where clients can be granted IRC operator status.  There are two required children elements, `username` and `password`, and one optional child, `ipmask`.  Here's an example entry that creates a new operator with the username `bob`, password `changeme`, and ipmask `*@google.com`:

	<?xml version="1.0" encoding="UTF-8"?>
	<operator>
		<username>bob</username>
		<password>changeme</password>
		<ipmask>*@google.com</ipmask>
	</operator>

In this example, only clients connecting from the host `google.com` would be allowed to log in.