# history

Longterm bash history with advanced search and select.

Manages a comprehensive history file that
allows searching and rerunning commands according to
executed command, working directory, time run, user, or host.


## Usage

* **h**[!] [*CONTEXT*] [*TIMESPEC*] [--] [*SEARCH*]...
  * Search history for pattern
* **dh**[!] [*CONTEXT*] [*TIMESPEC*] [--] [*SEARCH*]...
  * Show history of commands in this directory and subdirectories and optionally filter with pattern
* **ldh**[!] [*CONTEXT*] [*TIMESPEC*] [--] [*SEARCH*]...
  * Show history of commands in this directory only and optionally filter with pattern

### SEARCH
SEARCH matches the executed command.
It is interpreted as a `gawk` regular expression.
Multiple SEARCH arguments are joined with `.*`.

### TIMESPEC
TIMESPEC matches the timestamp and
is an argument of the form "[START..END]", (note the square brackets).
START and END are strings understood by `date`.
A single day may be specified by "[DATE]".

### CONTEXT
CONTEXT is an argument of the form "*USER*@*HOST*:*DIRECTORY*"
or "*USER*@*HOST*::*DIRECTORY*", where each field is optional.
"@" is used to specify user or host filters.
":" is used to specify a directory filter.
"::" may be used instead to exclude subdirectories.

### !
All three commands allow selecting from the 10 most recent entries
matching the filters by adding `!` to the command (ex. `h!`).
The selected command may be edited before it is executed.

The following command is also provided:

* **cd!** [*CONTEXT*] [*TIMESPEC*] [--] [*SEARCH*]
  * Select from recent working directories and optionally filter with pattern

## Examples

View all history
> h

View all commands matching the string `foo`
> h foo

View all commands run in this directory recursively
> dh

View all commands run in this directory only
> ldh

Select and edit from the most recent commands run in this directory only
> ldh!

View all commands starting with `echo`
> h ^echo

View all commands run yesterday containing `bar`
> h [yesterday] bar

View all commands run last week
> h [14 days ago..7 days ago]

View all commands run this month
> h [1 month ago..]

View all commands by user `baz`
> h baz@

View all commands run on hostname `host`
> h @host

View all commands containing the string `@host`
> h -- @host

View all commands run `/etc` recursively
> h :/etc

View all commands run in `/etc` only
> h ::/etc

View all commands run in the parent directory recursively
> h :..

Select from the most recent working directory locations
> cd!

Select from the most recent working directory locations running `vim`
> cd! ^vim

Select from the most recent working directory locations in `/etc`
> cd! :/etc


## Options

* `$ALL_HISTORY_FILE` - location of history file; default `~/.bash_all_history`


## Installation

Source `history.sh` in your .\*rc file.

### Dependencies

* gawk
* date
* less
* sed
* readlink
* gnu-coreutils
* bash


## License

history - v1.0

Copyright (C) 2014  Mara Kim, Kris Mcgary

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
