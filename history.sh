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
_OLDPWD="$OLDPWD"
HISTORY_INIT=""

# logging function
function _log_history {
if [ "$HISTORY_INIT" ]
then
 if [ "$_OLDPWD" = "$OLDPWD" ]
 then
  local directory="$(readlink -e -- "$PWD")"
 else
  local directory="$(readlink -e -- "$OLDPWD")"
  _OLDPWD="$OLDPWD"
 fi
 printf '%q %q %b\n\x00' "$USER@$HOSTNAME" "$directory" "$(cat <(history 1 | head -1 | sed 's/^ *[0-9]* *//') <(history 1 | tail -n +2))" >> "$ALL_HISTORY_FILE"
else
 HISTORY_INIT=1
fi
}

#grep history
function gh {
if [ "$1" ]
then
    grep -ze "$1" "$ALL_HISTORY_FILE"
else
    tr < "$ALL_HISTORY_FILE" -d '\000' | less +G
fi
}

#history of commands run in this directory and subdirectories (with grep)
function dh {
local directory="$(printf '%q' "$(readlink -e -- "$PWD")")"
if [ "$1" ]
then
    grep -Fze "$directory" "$ALL_HISTORY_FILE" | grep -ze "$1"
else
    grep -Fze "$directory" "$ALL_HISTORY_FILE"
fi
}

#history of commands run in this directory only (with grep)
function ldh {
local directory="$(printf '%q ' "$(readlink -e -- "$PWD")")"
if [ "$1" ]
then
    grep -Fze "$directory" "$ALL_HISTORY_FILE" | grep -ze "$1"
else
    grep -Fze "$directory" "$ALL_HISTORY_FILE"
fi
}

