# history
# persistent shell history with advanced search
#
# Copyright (C) 2013 Mara Kim, Kris McGary
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


#set up history logging of commands
export HISTTIMEFORMAT='%F %T '
PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND ; }"'printf "%q %q %b\n" "$USER@$HOSTNAME" "$(readlink -e -- "$PWD")" "$(cat <(history 1 | head -1 | cut -d " " -f4-) <(history 1 | tail -n +2))" >> ~/.bash_all_history'

#grep history
function gh {
if [ "$1" ]
then
    grep "$1" ~/.bash_all_history
else
    less +G ~/.bash_all_history
fi
}

#history of commands run in this directory and subdirectories (with grep)
function dh {
if [ "$1" ]
then
    grep -F "$(printf '%q' "$(readlink -e -- "$PWD")")" ~/.bash_all_history | grep "$1"
else
    grep -F "$(printf '%q' "$(readlink -e -- "$PWD")")" ~/.bash_all_history
fi
}

#history of commands run in this directory only (with grep)
function ldh {
if [ "$1" ]
then
    grep -F "$(printf '%q ' "$(readlink -e -- "$PWD")")" ~/.bash_all_history | grep "$1"
else
    grep -F "$(printf '%q ' "$(readlink -e -- "$PWD")")" ~/.bash_all_history
fi
}

