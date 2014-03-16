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
export HISTTIMEFORMAT='	%F %T	'
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
 \printf '%q\t%q\t%b\n\x00' "$USER@$HOSTNAME" "$directory" "$(\cat <(\history 1 | \head -1 | \sed 's/^[^\t]*\t//') <(\history 1 | \tail -n +2))" >> "$ALL_HISTORY_FILE"
fi
}

#gawk history
function gh {
    # read arguments
    local state
    local search
    local timespec

    for arg in "$@"
    do
        if [ "$state" = "input" ]
        then
            search="$search $arg"
        elif [ "$state" = "time" ]
        then
            timespec="$timespec $arg"
            if [ -z "${arg/*]/}" ]
              then state=""
            fi
        elif [ "$arg" = "-h" -o "$arg" = "--help" ]
        then
            \printf 'Usage: gh [TIMESPEC] [SEARCH]
Search history of commands.
TIMESPEC is an argument of the form "[START..END]",
where START and END are strings understood by `date`.
SEARCH is a regular expression understood by `gawk`.
'
            return 0
        elif [ "$arg" = "--" ]
          then state="input"
        elif [ -z "${arg/\[*/}" -a ! "$timespec" ]
        then
            timespec="$arg"
            if [ "${arg/*]/}" ]
              then state="time"
            fi
        else
            search="$search $arg"
        fi
    done

    local start_time
    local end_time
    if [ "${timespec/*..*/}" ]
    then
      timespec="${timespec#[}"
      timespec="${timespec%]}"
      start_time="$timespec"
      end_time="$timespec"
    else
      start_time="${timespec%..*}"
      start_time="${start_time#[}"
      end_time="${timespec#*..}"
      end_time="${end_time%]}"
    fi

if [ "$start_time" ]
  then start_time="$(date -d "$start_time" '+%F %T')"
fi
if [ "$end_time" ]
  then end_time="$(date -d "$end_time" '+%F %T')"
fi

local directory="$(\printf '%b' "$(\readlink -e -- "$PWD")")"
gawk -vstart_time="$start_time" -vend_time="$end_time"  -vsearch="$search" \
  'BEGIN { RS="\0"; FS="\t"; }
   { for(i = 5; i <= NF; i++) $4 = $4+$i }
   { if((length(start_time) == 0 || $3 >= start_time) &&
       (length(end_time) == 0 || $3 <= end_time) &&
       (length(search) == 0 || $4 ~ search )) printf "%s",$0}' "$ALL_HISTORY_FILE" |
    \tr -d '\000' | \less +G
}

#history of commands run in this directory and subdirectories (with grep)
function dh {
    # read arguments
    local state
    local search
    local timespec

    for arg in "$@"
    do
        if [ "$state" = "input" ]
        then
            search="$search $arg"
        elif [ "$state" = "time" ]
        then
            timespec="$timespec $arg"
            if [ -z "${arg/*]/}" ]
              then state=""
            fi
        elif [ "$arg" = "-h" -o "$arg" = "--help" ]
        then
            \printf 'Usage: dh [TIMESPEC] [SEARCH]
History of commands run in this directory and subdirectories
TIMESPEC is an argument of the form "[START..END]",
where START and END are strings understood by `date`.
SEARCH is a regular expression understood by `gawk`.
'
            return 0
        elif [ "$arg" = "--" ]
          then state="input"
        elif [ -z "${arg/\[*/}" -a ! "$timespec" ]
        then
            timespec="$arg"
            if [ "${arg/*]/}" ]
              then state="time"
            fi
        else
            search="$search $arg"
        fi
    done

    local start_time
    local end_time
    if [ "${timespec/*..*/}" ]
    then
      timespec="${timespec#[}"
      timespec="${timespec%]}"
      start_time="$timespec"
      end_time="$timespec"
    else
      start_time="${timespec%..*}"
      start_time="${start_time#[}"
      end_time="${timespec#*..}"
      end_time="${end_time%]}"
    fi

if [ "$start_time" ]
  then start_time="$(date -d "$start_time" '+%F %T')"
fi
if [ "$end_time" ]
  then end_time="$(date -d "$end_time" '+%F %T')"
fi

local directory="$(\printf '%b' "$(\readlink -e -- "$PWD")")"
gawk -vstart_time="$start_time" -vend_time="$end_time"  -vdirectory="$directory" -vsearch="$search" \
  'BEGIN { RS="\0"; FS="\t"; }
   { for(i = 5; i <= NF; i++) $4 = $4+$i }
   index($2,directory) == 1 {
       if((length(start_time) == 0 || $3 >= start_time) &&
       (length(end_time) == 0 || $3 <= end_time) &&
       (length(search) == 0 || $4 ~ search )) printf "%s",$0}' "$ALL_HISTORY_FILE" |
    \tr -d '\000' | \less +G
}

#history of commands run in this directory only (with grep)
function ldh {
    # read arguments
    local state
    local search
    local timespec

    for arg in "$@"
    do
        if [ "$state" = "input" ]
        then
            search="$search $arg"
        elif [ "$state" = "time" ]
        then
            timespec="$timespec $arg"
            if [ -z "${arg/*]/}" ]
              then state=""
            fi
        elif [ "$arg" = "-h" -o "$arg" = "--help" ]
        then
            \printf 'Usage: ldh [TIMESPEC] [SEARCH]
History of commands run in this directory only
TIMESPEC is an argument of the form "[START..END]",
where START and END are strings understood by `date`.
SEARCH is a regular expression understood by `gawk`.
'
            return 0
        elif [ "$arg" = "--" ]
          then state="input"
        elif [ -z "${arg/\[*/}" -a ! "$timespec" ]
        then
            timespec="$arg"
            if [ "${arg/*]/}" ]
              then state="time"
            fi
        else
            search="$search $arg"
        fi
    done

    local start_time
    local end_time
    if [ "${timespec/*..*/}" ]
    then
      timespec="${timespec#[}"
      timespec="${timespec%]}"
      start_time="$timespec"
      end_time="$timespec"
    else
      start_time="${timespec%..*}"
      start_time="${start_time#[}"
      end_time="${timespec#*..}"
      end_time="${end_time%]}"
    fi

if [ "$start_time" ]
  then start_time="$(date -d "$start_time" '+%F %T')"
fi
if [ "$end_time" ]
  then end_time="$(date -d "$end_time" '+%F %T')"
fi

local directory="$(\printf '%b' "$(\readlink -e -- "$PWD")")"
gawk -vstart_time="$start_time" -vend_time="$end_time"  -vdirectory="$directory" -vsearch="$search" \
  'BEGIN { RS="\0"; FS="\t"; }
   { for(i = 5; i <= NF; i++) $4 = $4+$i }
   index($2,directory) == 1 && length($2) == length(directory) {
       if((length(start_time) == 0 || $3 >= start_time) &&
          (length(end_time) == 0 || $3 <= end_time) &&
          (length(search) == 0 || $4 ~ search )) printf "%s",$0}' "$ALL_HISTORY_FILE" |
    \tr -d '\000' | \less +G
}

