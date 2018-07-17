![Raven IRCd](https://github.com/danhetrick/raven-ircd/blob/master/raven-ircd.png?raw=true)

# Raven IRCd

**Raven IRCd** (or rIRCd) is an [open-source](#license) [IRC](https://en.wikipedia.org/wiki/Internet_Relay_Chat) [server](https://en.wikipedia.org/wiki/IRCd) written in [Perl](https://en.wikipedia.org/wiki/Perl), with [POE](http://poe.perl.org/).  It is still very much a work in progress, but its base functionality is complete.  [Clients](https://en.wikipedia.org/wiki/Comparison_of_Internet_Relay_Chat_clients) can connect to it, join [channels](https://en.wikipedia.org/wiki/Internet_Relay_Chat#Channels), chat, send private messages, and do [all the things that other IRCds can do](https://en.wikipedia.org/wiki/List_of_Internet_Relay_Chat_commands).

**Raven IRCd** was written with cross-platform compatability in mind. It has been tested on Windows 10, Debian Linux, and Ubuntu Linux.  I don't have access to any Apple hardware, but I wouldn't be surprised if it ran on OSX.  If you can run **Raven IRCd** on your Apple device, [let me know](mailto:dhetrick@gmail.com)!

The source code for `raven-ircd.pl` is *heavily* commented. I try to explain everything the program is doing in detail, so if you want to use it as a base for your own IRCd, the **Raven IRCd** source is a good place to start.  The most complicated part of the source is the code for loading and applying configuration file settings, and thus has the most comments; it's written in pure Perl, and doesn't require POE or anything outside of the standard library (besides XML::TreePP, included with the **Raven IRCd** distribution).  If you do use **Raven IRCd** as the base for your own IRC server, remember the [license](#license), and make sure to share your additions/changes.

The latest version of **Raven IRCd** is 0.0352.

# Features
* _**Fast Setup**_ - **Raven IRCd** can be setup and ran in less than a minute!
* _**Configurable**_ - Run **Raven IRCd** with the [default settings](#default-settings), or [configure](#configuration) to your heart's content!  Configuration files are written in [easy-to-read XML](#configuration-file-format).
* _**Open-Source**_ - Licensed under [GPL v3](#license). Free to use for both commercial and non-commercial purposes. Base your own IRCd on **Raven IRCd**!
* _**Built-in Administration**_ - An [OperServ](#operserv) is built into the IRC server, and is easy to configure!
* _**Cross-Platform**_ - Run it under your favorite flavor of Windows, Linux, or BSD!

# A new IRCd? Aren't there already [a](http://www.ircd-hybrid.org/) [bunch](https://www.unrealircd.org/) [of](http://www.inspircd.org/) [those](https://www.ratbox.org/) [available](http://pure-ircd.sourceforge.net/)? [You're reinventing the wheel!](https://en.wikipedia.org/wiki/Reinventing_the_wheel)

Yes, there are, and there are ones with a lot more features than **Raven IRCd**!  However, all the ones I could find for my platform (Windows 10) were fairly difficult to configure.  Most of them said in the documentation that I could expect to spend 30 or 40 minutes digging through dense configuration files *before* I could even start the server; many of these same IRCds introduced *intentional errors* in the config files so you would *be required* to spend time reading them and changing settings.

This is good, I suppose, if you're planning on running an IRC server with hundreds or thousands of users, connecting to one of the big networks, like [Undernet](http://www.undernet.org/) or [EFnet](http://www.efnet.org/).  But what if you just want to run a server for five or six of your friends?  A server for your class in school, your office, or your home?

**Raven IRCd** was born when I had a need for a IRCd that was *really* easy to set up and configure quickly. At the time, I was writing an [IRC bot](https://en.wikipedia.org/wiki/IRC_bot) ([IRC-patch](https://github.com/danhetrick/ircpatch)) and I needed a server I could test the bot with.  I didn't really care how the server ran, as long as it ran like a basic IRC server.  I fought with the configuration files of [Unreal IRCd](https://www.unrealircd.org/), and after 45 minutes or so or reading and tweaking, had the server up and running. That was time that I could have spent writing and testing [my bot](https://github.com/danhetrick/ircpatch), and it was more than a little frustrating.  **Raven IRCd** was written to address this frustration; it's easy to configure and run, but if you want to delve into more custom configuration, you can do that, too.  Fast, easy, and configurable: this is an IRCd you can start using with less than 1 minute spent on configuration!

# What is **Raven IRCd** recommended for?

* :thumbsup: **Raven IRCd** __*is*__ recommended for testing IRC software, and small user bases.  Suggested uses would be for a LAN party, small development groups, your roommates, classmates, friends, or family.

* :thumbsdown: **Raven IRCd** __*is not*__ recommended for use with the big networks or with a large user base. If you want to run an IRCd that will host a lot of clients, or connect to an established IRC network, don't use **Raven IRCd**; use one of the more robust IRCds, and spend the time to configure it properly and securely. I recommend [Unreal IRCd](https://www.unrealircd.org/) or [Hybrid IRCd](http://www.ircd-hybrid.org/).

# Requirements

[Perl](https://en.wikipedia.org/wiki/Perl), [POE](http://poe.perl.org/) (available from [CPAN](https://www.cpan.org/)), [POE::Component::Server::IRC](https://metacpan.org/pod/POE::Component::Server::IRC) (available from [CPAN](https://www.cpan.org/)), [XML::TreePP](https://metacpan.org/pod/XML::TreePP) (included with the base installation, but also from available from [CPAN](https://www.cpan.org/)).

# Files

* :file_folder: lib
	* :page_facing_up: OperServ.pm
	* :page_facing_up: RavenConfigFile.pm
	* :page_facing_up: RavenIRCd.pm
	* :file_folder: XML
		* :page_facing_up: TreePP.pm
* :file_folder: settings
	* :page_facing_up: authorized.xml
	* :page_facing_up: default.xml
	* :page_facing_up: operators.xml
* :page_facing_up: LICENCE
* :page_facing_up: raven-ircd.pl
* :page_facing_up: raven-ircd.png
* :page_facing_up: README.md
	
------------
# Table of Contents

* [Usage](#usage)
* [Configuration](#configuration)
	* [Default Configuration Files](#default-configuration-files)
	* [Default Settings](#default-settings)
		* [`config` defaults](#config-defaults)
		* [`auth` defaults](#auth-defaults)
		* [`operator` defaults](#operator-defaults)
		* [`operserv` defaults](#operserv-defaults)
	* [Configuration File Format](#configuration-file-format)
		* [Configuration File Restrictions](#configuration-file-restrictions)
		* [`import` element](#import-element)
		* [`config` element](#config-element)
			* [`config` child elements](#config-child-elements)
		* [`auth` element](#auth-element)
			* [`auth` child elements](#auth-child-elements)
		* [`operator` element](#operator-element)
			* [`operator` child elements](#auth-child-elements)
		* [`operserv` element](#operserv-element)
			* [`operserv` child elements](#operserv-child-elements)
	* [Example Configuration File](#example-configuration-file)
* [OperServ](#operserv)
	* [OperServ Usage](#operserv-usage)
	* [OperServ Commands](#operserv-commands)
		* [`clear`](#clear-channel)
		* [`join`](#join-channel)
		* [`part`](#part-channel)
		* [`mode`](#mode-channel-mode)
		* [`op`](#mode-channel-user)
* [License](#license)

# Usage

	perl raven-ircd.pl OPTIONS

	Options:
	--help or -h			Displays usage information
	--config FILE or -c FILE	Runs Raven IRCd with default settings
	--warn or -w			Turns warnings on
	--verbose or -v			Turns verbose on
	--quiet or -q			Run silently
	--nobanner or -n		Don't display Raven IRCd banner

	Options can be bundled; so, to turn on verbose and warning, use -vw

## Options

* `--help` or `-h`
	* Displays usage information.
* `--config FILE` or `-c FILE`
	* Starts up **Raven IRCd** with `FILE` as the configuration file.
* `--verbose` or `-v`
	* Turns on verbose mode.  **Raven IRCd** will print text to the console to tell the user what it's doing.
* `--warn` or `-w`
	* Turns on warnings. **Raven IRCd** will print text to the console, warning users of non-fatal errors. If warnings are turned on, they will still print to the console if `--verbose` is not turned on.
* `--quiet` or `-q`
	* **Raven IRCd** will not print *anything* to the console except fatal errors.
* `--nobanner` or `-n`
	* Turns off the **Raven IRCd** banner that `raven-ircd.pl` prints on startup.

Configuration files will be looked for in two places:  first, the same directory that `raven-ircd.pl` is located in (called the **home directory**), and second, the `settings/` directory in the same directory as `raven-ircd.pl` (called the **settings directory**).

If ran with no options, or without the `--config` option, **Raven IRCd** will load the default set of configuration files, `default.xml` (which also loads `operators.xml` and `authorized.xml`), located in the **settings directory**.

If ran with the `--config` option, **Raven IRCd** will load the specified file instead of `default.xml`.

Any settings that are missing or not set in any configuration file(s) loaded will be set to default values (see [Default settings](#default-settings)).

By default, **Raven IRCd** will print the banner to the console on start up, and nothing else.  To print information about what file and settings are loaded, use the `--verbose` option. To print possible non-fatal errors, use the `--warn` option. To print *nothing* to the console while running, use the `--quiet` option.  To prevent the banner from being printed, use the `--nobanner` option.

Options can be shortened to one dash and one letter, the first letter of the command.  For example, the `--verbose` option can be shortened to `-v`.  Options can also be bundled, allowing more than one option to be set at a time;  for example, to turn on verbose mode and warnings, you could use `-vw`.

# Configuration

All server configuration is done through one or more [XML](https://en.wikipedia.org/wiki/XML)-like configuration files; the default configuration file is named `default.xml`, and is located in the **settings** directory.

All configuration elements can be set in *any* configuration file loaded by **Raven IRCd**, and do not have to be in `default.xml`.

## Default Configuration Files

In the default configuration, **Raven IRCd** ships with three configuration files:  `default.xml`, `authorized.xml`, and `operators.xml`.  `default.xml` contains basic server settings, and `import`s (see [`import` element](#import-element)) `authorized.xml` and `operators.xml`. `authorized.xml` contains any auth entries (see [`auth` element](#auth-element)); by default, it contains only one, allowing anyone to connect.  `operators.xml` contains any operator account entries (see [`operator` element](#operator-element)); by default, it doesn't contain *any* functional operator accounts, only a commented-out one that you can uncomment and edit.

## Default Settings

### `config` defaults

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
* `config`->`admin`
	* `-----------------`
	* `Raven IRCd 0.0352`
	* `-----------------`
* `config`->`description`
	* Raven IRCd 0.0352
* `config`->`motd`
	* motd.txt

### `auth` defaults

* `auth`->`mask`
	* \*@\*

### `operator` defaults

* `operator`
	* No operators are defined

### `operserv` defaults

* `operserv`->`use`
	* 0
* `operserv`->`control`
	* 0
* `operserv`->`nick`
	* OperServ
* `operserv`->`username`
	* The OperServ bot

## Configuration File Format

**Raven IRCd** configuration files are written in an XML-like language called _Raven XML_;  the first line in a _Raven XML_ must be a declaration (`<?raven-xml version="1.0"?>`), and it uses the file extension `.xml`. The main difference between the XML format and the format used for **Raven IRCd** configuration files is that, unlike XML, **Raven IRCd** configuration files can have multiple root elements.  There are five root elements in a **Raven IRCd** configuration file: [`config`](#config-element), [`import`](#import-element), [`auth`](#auth-element), [`operator`](#operator-element), and [`operserv`](#operserv-element).  All root elements have mandatory and/or optional child elements (with the exception of `import`, which has no child elements): `config` has _no_ manditory child elements, `auth` elements have _one_ mandatory child element ([`mask`](#mask)), `operator` has *two* mandatory child elements ([`username`](#username) and [`password`](#password-operator)), and `operserv` has *one* mandatory child element ([`use`](#use)).  See [Restrictions](#configuration-file-restrictions) for more information.

### Configuration File Restrictions

* Configuration files _**must**_ begin with `<?raven-xml version="1.0"?>`.  It must be the first line in the configuration file, with no comments,content, or whitespace preceeding it. 

* Configuration files are only allowed to have **_one_ [`config`](#config-element) _element in each file_**; each `config` element is only allowed to have **one** of the following child elements: [`verbose`](#verbose), [`banner`](#banner), [`warn`](#warn), [`name`](#name), [`nicklength`](#nicklength), [`network`](#network), [`max_targets`](#max_targets),[`max_channels`](#max_channels), [`info`](#info), [`description`](#description), [`motd`](#motd).  Each `config` element is allowed to have three (3) [`admin`](#admin) child elements. Each `config` element is allowed to have multiple [`port`](#port) child elements.  All `config` child elements are optional.

* Configuration files are only allowed to have **_one_ [`operserv`](#operserv-element) _element in each file_**; each `operserv` element is only allowed to have **one** of the following child elements: [`use`](#use) (which is mandatory), and [`nick`](#nick) (which is optional).

* Configuration files are allowed to have **_multiple_ [`import`](#import-element) _elements_**. `import` elements have no child elements.

* Configuration files are allowed to have **_multiple_ [`auth`](#auth-element) _elements_**; each `auth` element is only allowed to have **_one_** of the following child elements: [`mask`](#mask), [`password`](#password-auth), [`spoof`](#spoof), [`no_tilde`](#no_tilde). All `auth` elements **_must have a_** `mask` **_child element_**; all other `auth` child elements are optional.

* Configuration files are allowed to have **_multiple_ [`operator`](#operator-element) _elements_**; each `operator` element is only allowed to have **_one_** of the following child elements: [`username`](#username), [`password`](#password-operator), [`ipmask`](#ipmask). All `operator` elements **_must have_** `username` **_and_** `password` **_child elements_**; `ipmask` child element is optional.

------------
### `import` element

The `import` element is used to load configuration data from external files, much like C's `#include` preprocesser directive.  **Raven IRCd** will look for `import`'ed files first in the **home** directory, then in the **settings** directory.  The `import` element has no children elements.  Multiple `import` elements can be set, and they can be set in any configuration file loaded;  thus, `import`'ed files can contain `import` elements, which can *also* contain `import` elements, and so on.

-----------
### `config` element

The `config` element is where all the main server settings are.  They are all optional; the server will use a listening port of `6667` and let anyone connect to it.  `config` has a number of children elements, all optional.  Here's an example of a basic `config` entry, with all default settings:

	<?raven-xml version="1.0"?>
	<config>
		<port>6667</port>
		<name>raven.irc.server</name>
		<nicklength>15</nicklength>
		<network>RavenNet</network>
		<max_targets>4</max_targets>
		<max_channels>15</max_channels>
		<info>Raven IRCd</info>
		<admin>Raven IRCd 0.0352</admin>
		<admin>The operator of this server didn't set up the admin option.</admin>
		<admin>Sorry!</admin>
		<description>Raven IRCd 0.0352</description>
		<motd>motd.txt</motd>
	</config>

Multiple `config` elements can be set (although they must be in separate files; see [Restrictions](#configuration-file-restrictions)), though it may confuse the server (and you!). Configuration files are processed in order;  for example, if a file is imported with the `import` element, it will be loaded before any other elements following the `import` element are loaded.  As an example, let's say that you have two configuration files that you want to use, `mysettings.xml` and `othersettings.xml`.

	<?raven-xml version="1.0"?>
	<!-- mysettings.xml -->
	<config>
		<port>6667</port>
		<nicklength>1000000</nicklength>
		<network>ScoobyDooNet</network>
	</config>

	<import>othersettings.xml</import>

As you can see, this file sets the listening port to 6667, the nick length to a generous 1,000,000 characters, the network name to "ScoobyDooNet", and `import`s another configuration file, "othersettings.xml":

	<?raven-xml version="1.0"?>
	<!-- othersettings.xml -->
	<config>
		<nicklength>2</nicklength>
	</config>

When all the configuration files are loaded, our users lose the generous nick length of 1,000,000 characters, and now are left with a paltry 2 character limit for their nickname.  Why?  Even though `mysettings.xml` was loaded *first*, `othersettings.xml` was loaded after it, and changed the nick length from 1,000,000 to 2.  If we had `import`'ed `othersettings.xml` before we set our config element, the nick length of 1,000,000 would still be set (because the `nicklength` setting in `mysettings.xml` was loaded *after* the `nicklength` setting in `othersettings.xml`).

The only exception to this rule is the [`port` child element](#port);  it doesn't overwrite `port` elements in any other configuration file.  New `port` elements just add new listening ports without removing previously set ports.

#### `config` child elements

* [port](#port)**\***
* [name](#name)**\***
* [nicklength](#nicklength)**\***
* [network](#network)**\***
* [max_targets](#max_targets)**\***
* [max_channels](#max_channels)**\***
* [info](#info)**\***
* [admin](#admin)**\***
* [description](#description)**\***
* [motd](#motd)**\***

Elements marked with an asterix (**\***) are optional.

------------
##### `port`

Sets the [port](https://en.wikipedia.org/wiki/Port_(computer_networking)) that **Raven IRCd** will listen on.  Multiple `port` elements can exist; each one will spawn a listener on the given port. If `port` is set to something non-numeric, `raven-ircd.pl` will display an error and exit. 

------------
##### `name`

Sets the server's name.

------------
##### `nicklength`

Sets the maximum number of characters that can be used in a client's nick. If `nicklength` is set to something non-numeric, `raven-ircd.pl` will display an error and exit.  

------------
##### `network`

Sets the name of the network **Raven IRCd** will use.

------------
##### `max_targets`

Sets the maximum number of clients a user can send a private message to in one operation. If `max_targets` is set to something non-numeric, `raven-ircd.pl` will display an error and exit. 

------------
##### `max_channels`

Sets the maximum number of channels a client can join. If `max_channels` is set to something non-numeric, `raven-ircd.pl` will display an error and exit. 

------------
##### `info`

Sets the text displayed with the `info` IRC command.

------------
##### `admin`

Sets the text returned by the `/admin` IRC command. Each `admin` element adds one line to the admin text, with a maximum of three lines allowed. If more than three lines are added (that is, if there's more than three `admin` elements), only the first three `admin` elements are used, and the user is warned. If only one or two `admin` elements are set, the other line(s) are set to be blank. If no `admin` elements are set, the default values are used (see [Default settings](#default-settings)).

------------
##### `description`

Sets the server's description text.

------------
##### `motd`

Sets the name of the file containing the "Message of the Day", or MOTD.  The server will look for the MOTD file first in the **home** directory, and then in the **settings** directory.

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

Removes the tilde (~) from reported hostmaks.  Set to 1 to remove the tilde, and set to 0 to leave the tilde in place.  If `no_tilde` is set to something other than 0 or 1, `raven-ircd.pl` will display an error and exit.   Not a required child element.

------------
### `operator` element

The `operator` element is where clients can be granted IRC operator status.  There are two required children elements, `username` and `password`, and one optional child, `ipmask`.  Here's an example entry that creates a new operator with the username `bob`, password `changeme`, and ipmask `192.168.0.*`:

	<operator>
		<username>bob</username>
		<password>changeme</password>
		<ipmask>192.168.0.*</ipmask>
	</operator>

In this example, only clients connecting from an IP address that starts with "192.168.0." would be allowed to log in to this operator account.  `operator`  is optional (server will start with no operators set). Multiple `operator` elements can be set.

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

Sets what IP addresses are allowed to use this operator account.  Not a required child element. Use **\*** for a multiple character wild card, or **?** for a single character wild card.  For example, if you're on a LAN with all internal IP addresses starting with "192.168.1", to allow only people on your LAN to become operators, use an ipmask of "192.168.1.\*".

------------

### `operserv` element

The `operserv` element activates and configures an OperServ bot for your server.  `operserv` is optional.

	<operserv>
		<use>0</use>
		<nick>OperServ</nick>
		<control>0</control>
		<username>The OperServ bot</username>
	</operserv>

#### `operserv` child elements

* [use](#use)
* [nick](#nick)**\***
* [control](#control)**\***
* [username](#username-operserv)**\***

Elements marked with an asterix (**\***) are optional.

------------
##### `use`

Activates the OperServ bot if set to 1, leaves it turned off if set to 0.  If `use` is set to something other than 0 or 1, `raven-ircd.pl` will display an error and exit. 

------------
##### `nick`

Sets the OperServ's IRC nick.

------------
##### `control`

Set to 1 to turn on channel control mode, and 0 to turn it off. In channel control mode, OperServ will join any channel a user joins, claiming ops for itself (denying the joining user ops). If `control` is set to something other than 0 or 1, `raven-ircd.pl` will display an error and exit. 

------------
##### `username` (operserv)

Sets the OperServ's username.

------------
## Example Configuration File

Here's an example configuration file.  It'll set up listening ports on ports 6667-6669, allow anyone to connect (spoofing their host to appear as if they are connecting from `facebook.com`), and create an operator with the username `oracle` and the password `thematrix`.  The server's name with be "example.raven.setup" on the "OscarNet" network, and will allow clients to connect to 50 channels and a time, and let them use only 8 characters in their nick:

	<?raven-xml version="1.0"?>
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

	user@localhost:$ perl raven-ircd.pl --config oscarnet.xml --verbose

	██████╗  █████╗ ██╗   ██╗███████╗███╗   ██╗     I
	██╔══██╗██╔══██╗██║   ██║██╔════╝████╗  ██║     R
	██████╔╝███████║██║   ██║█████╗  ██╔██╗ ██║     C
	██╔══██╗██╔══██║╚██╗ ██╔╝██╔══╝  ██║╚██╗██║     d
	██║  ██║██║  ██║ ╚████╔╝ ███████╗██║ ╚████║     *
	╚═╝  ╚═╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝╚═╝  ╚═══╝     *
	                                   VERSION 0.0352
	                                   
	[3:59:53 6/17/2018] Loaded configuration file 'oscar.xml'
	[3:59:53 6/17/2018] Added MOTD from 'settings/motd.txt'
	[3:59:53 6/17/2018] Adding authorized entries from 'oscar.xml'
	[3:59:53 6/17/2018] 1 auth entry loaded
	[3:59:53 6/17/2018] Added operator entries from 'oscar.xml'
	[3:59:53 6/17/2018] 1 operator entry loaded
	[3:59:53 6/17/2018] Added a listener on port '6667'
	[3:59:53 6/17/2018] Added a listener on port '6668'
	[3:59:53 6/17/2018] Added a listener on port '6669'

**Raven IRCd** is up and running!  Connect to it on port 6667, 6668, or 6669 and chat away!

------------
# OperServ

**Raven IRCd** has an optional OperServ bot built into it.  To turn it on, create a `operserv` element in you config file, and set `operserv`'s child element `use` to 1. You can change the nick the OperServ uses by setting `operserv`'s child element `nick` to the desired nick.

**Raven IRCd** features a special option for OperServ: channel control mode. If this is turned on (set `operserv`'s child element `control` to 1), whenever a user joins a "new" channel (one that no one was in before the join), OperServ will join that channel *before* the user joins it, claiming ops status for itself.

## OperServ Usage

If activated, the Operserv will join the server as soon as the server starts, and will be ready to take commands.  All commands require that the issuing user is an operator (see [`operator`](#operator-element) for information on how to create operator accounts).  Once active, operators can issue commands to OperServ by sending a private message containing the command and any arguments.

### OperServ Commands

* [`clear`](#clear-channel)
* [`join`](#join-channel)
* [`part`](#part-channel)
* [`mode`](#mode-channel-mode)
* [`op`](#mode-channel-user)

#### `clear <CHANNEL>`

OperServ will remove all channel modes on the indicated channel, including all users' `+ov` flags. The timestamp of the channel will be reset and the OperServ will join that channel with `+o`.

------------
#### `join <CHANNEL>`

OperServ will join the channel specified with `+o`.

------------
#### `part <CHANNEL>`

OperServ will part the channel specified.

------------
#### `mode <CHANNEL> <MODE>`

OperServ will set the channel mode you tell it to. You can also remove the channel mode by prefixing the mode with a '-' (minus) sign.

------------
#### `op <CHANNEL> <USER>`

The OperServ will give +o to any user on a channel you specify. OperServ does not need to be in that channel (as this is mostly a server hack).

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
