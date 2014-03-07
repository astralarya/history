# history
# persistent shell history with advanced search
#
# Copyright (C) 2013 Kris McGary, Mara Kim
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along with
# this program. If not, see http://www.gnu.org/licenses/.


### USAGE ###
# Source this file in your shell's .*rc file


### SETTINGS ###

ALL_HISTORY_FILE=~/.bash_all_history

### END SETTINGS ###


#set up history logging of commands
export HISTTIMEFORMAT='%F %T '
PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND;} _log_history"
_PWD="$PWD"
_HISTORY_INDEX=

# logging function
function _log_history {
local curr_index="$(\history 1 | \head -1 | \sed 's/^ *\([0-9]*\).*/\1/')" 
if [ -z "$_HISTORY_INDEX" ]
then
 # first prompt of session
 _HISTORY_INDEX="$curr_index"
elif [ "$_HISTORY_INDEX" != "$curr_index" ]
then
 _HISTORY_INDEX="$curr_index"
 if [ "$_PWD" = "$PWD" ]
 then
  local directory="$(\readlink -e -- "$PWD")"
 else
  local directory="$(\readlink -e -- "$OLDPWD")"
  _PWD="$PWD"
 fi
 \printf '%q %q %b\n\x00' "$USER@$HOSTNAME" "$directory" "$(\cat <(\history 1 | \head -1 | \sed 's/^ *[0-9]* *//') <(\history 1 | \tail -n +2))" >> "$ALL_HISTORY_FILE"
fi
}

#grep history
function gh {
if [ "$*" ]
then
    \grep -ze "$(\printf '%s.*' "$@")" "$ALL_HISTORY_FILE"
else
    \tr < "$ALL_HISTORY_FILE" -d '\000' | \less +G
fi
}

#history of commands run in this directory and subdirectories (with grep)
function dh {
local directory="$(\printf '%q' "$(\readlink -e -- "$PWD")")"
if [ "$*" ]
then
    \grep -Fze "$directory" "$ALL_HISTORY_FILE" | \grep -ze "$(\printf '%s.*' "$@")"
else
    \grep -Fze "$directory" "$ALL_HISTORY_FILE"
fi
}

#history of commands run in this directory only (with grep)
function ldh {
local directory="$(\printf '%q ' "$(\readlink -e -- "$PWD")")"
if [ "$*" ]
then
    \grep -Fze "$directory" "$ALL_HISTORY_FILE" | \grep -ze "$(\printf '%s.*' "$@")"
else
    \grep -Fze "$directory" "$ALL_HISTORY_FILE"
fi
}

