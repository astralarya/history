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

TIMESPEC is an argument of the form "[START..END]", (note the square brackets)
where START and END are strings understood by `date`.  
SEARCH is a regular expression understood by `gawk` used to match the executed command.  
An "@" is used to specify user or host.

All three commands allow selecting from the 10 most recent entries
by adding `!` to the command (ex. `gh!`).
The selected command may be edited before it is executed.


## Options

* `$ALL_HISTORY_FILE` - location of history file; default `~/.bash_all_history`


## Installation

Source `history.sh` in your .\*rc file.
