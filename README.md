# history

Longterm bash history with advanced search and select.
Manages a comprehensive history file that
allows searching and rerunning commands according to
executed command, working directory, time run, user, or host.


## Usage

* **gh**[!] [[*USER*]@[*HOST*]] [*TIMESPEC*] [--] [*SEARCH*]
  * Search history for pattern
* **dh**[!] [[*USER*]@[*HOST*]] [*TIMESPEC*] [--] [*SEARCH*]
  * Show history of commands in this directory and subdirectories and optionally filter with pattern
* **ldh**[!] [[*USER*]@[*HOST*]] [*TIMESPEC*] [--] [*SEARCH*]
  * Show history of commands in this directory only and optionally filter with pattern

SEARCH is a regular expression understood by `gawk` used to match the executed command.

TIMESPEC is an argument of the form "[START..END]", (note the square brackets)
where START and END are strings understood by `date`.
A single day may be specified by "[DATE]".

An "@" is used to specify user or host.

All three commands allow selecting from the 10 most recent entries
matching the filters by adding `!` to the command (ex. `gh!`).
The selected command may be edited before it is executed.

### Examples

View all history
> gh

View all commands matching the string `foo`
> gh foo

View all commands starting with `echo`
> gh ^echo

View all commands run yesterday containing `bar`
> gh [yesterday] bar

View all commands run last week
> gh [14 days ago..7 days ago]

View all commands run this month
> gh [1 month ago..]

View all commands run in this directory recursively
> dh

View all commands run in this directory only
> ldh

Select and edit from the most recent commands run in this directory only
> ldh!

View all commands by user `baz`
> gh baz@

View all commands run on hostname `host`
> gh @host

## Options

* `$ALL_HISTORY_FILE` - location of history file; default `~/.bash_all_history`


## Installation

Source `history.sh` in your .\*rc file.
