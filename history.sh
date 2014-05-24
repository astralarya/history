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
export HISTCONTROL=''
PROMPT_COMMAND="_log_history; ${PROMPT_COMMAND}"
_PWD="$(pwd -P)"
__PWD="$_PWD"
_HISTNUM=""
_LAST_COMMAND=""

# logging function
function _log_history {
_PWD="$(pwd -P)"
local histnum="$(history 1 | sed 's/ *\([0-9]*\).*/\1/')"
if [ -z "$_HISTNUM" ]
then
 _HISTNUM="$histnum"
elif [ "$histnum" != "$_HISTNUM" ]
then
 if [ "$__PWD" = "$_PWD" ]
 then
  local directory="$_PWD"
 else
  local directory="$__PWD"
  __PWD="$_PWD"
 fi
 printf '%q\t%q\t%b\n\x00' "$USER@$HOSTNAME" "$directory" "$(cat <(history 1 | head -1 | sed 's/^[^\t]*\t//') <(history 1 | tail -n +2))" >> "$ALL_HISTORY_FILE"
 local command="$(cat <(history 1 | head -1 | sed 's/^[^\t]*\t[^\t]*\t//') <(history 1 | tail -n +2))"
 if [ "$_LAST_COMMAND" = "$command" ]
 then
  history -d "$histnum"
 else
  _HISTNUM="$histnum"
  _LAST_COMMAND="$command"
 fi
fi
}

# gawk history
gh () {
  gawk_history "/" 1 "$@" | tr -d '\000' | less -FX +G
}

#history of commands run in this directory and subdirectories (with grep)
dh () {
  gawk_history "$(printf '%b' "$(pwd -P)")" 1 "$@" | tr -d '\000' | less -FX +G
}

#history of commands run in this directory only (with grep)
ldh () {
  gawk_history "$(printf '%b' "$(pwd -P)")" 0 "$@" | tr -d '\000' | less -FX +G
}

# select from history
gh! () {
  select_history "/" 1 "$@"
}

# select from history
dh! () {
  select_history "$(printf '%b' "$(pwd -P)")" 1 "$@"
}

# select from history
ldh! () {
  select_history "$(printf '%b' "$(pwd -P)")" 0 "$@"
}

# select history implementation
select_history () {
  local histline
  local history
  local item
  local _scs_col="\e[0;32m"
  local _trn_col='\e[0;33m'

  while \read -r -d '' histline
  do
      history+=( "$histline" )
  done < <( gawk_history "$@" |
            gawk 'BEGIN { RS="\0"; FS="\t"; }
            { for(i = 5; i <= NF; i++) $4 = $4 "\t" $i}
            { a[$4] = NR }
            END { PROCINFO["sorted_in"] = "@val_num_desc";
                  num = 0;
                  for (i in a) { printf "%s\0", i; num++; if (num == 10) break } }' )

  select item in "${history[@]}"
  do
      if [ -z "$item" ]
      then break
      fi

      read -e -i "$item" -p '$ ' item
      history -s "$item"
      eval "$item"
      break
  done
}


# core gawk history implementation
gawk_history () {
    # read arguments
    local state="first"
    local search
    local timespec
    local user
    local host
    local directory
    local recursive_dir

    for arg in "$@"
    do
        if [ "$state" = "first" ]
        then
            directory="$arg"
            state="second"
        elif [ "$state" = "second" ]
        then
            recursive_dir="$arg"
            state=""
        elif [ "$state" = "input" ]
        then
            search+="$arg"
        elif [ "$state" = "time" ]
        then
            timespec="$timespec $arg"
            if [ -z "${arg/*]/}" ]
              then state=""
            fi
        elif [ "$arg" = "-h" -o "$arg" = "--help" ]
        then
            if [ "$recursive_dir" = 0 ]
            then printf 'Usage: ldh [TIMESPEC] [[USER]@[HOST]] [--] [SEARCH]
History of commands run in this directory only
TIMESPEC is an argument of the form "[START..END]",
where START and END are strings understood by `date`.
An "@" is used to specify user or host.
SEARCH matches against the command. 
'
            elif [ "$directory" = "/" ]
            then printf 'Usage: gh [TIMESPEC] [[USER]@[HOST]] [--] [SEARCH]
Search history of commands.
TIMESPEC is an argument of the form "[START..END]",
where START and END are strings understood by `date`.
An "@" is used to specify user or host.
SEARCH matches against the command. 
'
            else printf 'Usage: dh [TIMESPEC] [[USER]@[HOST]] [--] [SEARCH]
History of commands run in this directory and subdirectories
TIMESPEC is an argument of the form "[START..END]",
where START and END are strings understood by `date`.
An "@" is used to specify user or host.
SEARCH matches against the command. 
'
            fi
            return 0
        elif [ "$arg" = "--" ]
          then state="input"
        elif [ -z "${arg/\[*/}" -a ! "$timespec" ]
        then
            timespec="$arg"
            if [ "${arg/*]/}" ]
              then state="time"
            fi
        elif [ -z "${arg/*@*/}" ]
        then
            if [ "${arg%%@*}" -a ! "$user" ]
            then
              user="${arg%%@*}" 
            fi
            if [ "${arg#*@}" -a ! "$host" ]
            then
              host="${arg#*@}" 
            fi
        else
            search+="$arg"
        fi
    done

    local start_time
    local end_time
    if [ "${timespec/*..*/}" ]
    then
      timespec="${timespec#[}"
      timespec="$(date -d "${timespec%]}" '+%F')"
      start_time="$timespec"
      end_time="$timespec + 1day"
    else
      start_time="${timespec%..*}"
      start_time="${start_time#[}"
      end_time="${timespec#*..}"
      end_time="${end_time%]}"
    fi

    if [ "$start_time" ]
    then
      start_time="$(date -d "$start_time" '+%F %T')"
      if [ -z "$start_time" ]
      then
        return 1
      fi
    fi
    if [ "$end_time" ]
    then
      end_time="$(date -d "$end_time" '+%F %T')"
      if [ -z "$end_time" ]
      then
        return 1
      fi
    fi

    if [ "$recursive_dir" = 0 ]
    then gawk -vdirectory="$directory" -vstart_time="$start_time" -vend_time="$end_time" -vsearch="$search" -vhost="$host" -vuser="$user" \
      'BEGIN { RS="\0"; FS="\t"; user_matcher="^"user"(@|$)"; host_matcher="[^@]*@"host;}
       { for(i = 5; i <= NF; i++) $4 = $4 "\t" $i}
       index($2,directory) == 1 && length($2) == length(directory) {
           if((length(start_time) == 0 || $3 >= start_time) &&
              (length(end_time) == 0 || $3 <= end_time) &&
              (length(user) == 0 || $1 ~ user_matcher ) &&
              (length(host) == 0 || $1 ~ host_matcher ) &&
              (length(search) == 0 || $4 ~ search )) printf "%s\t%s\t%s\t%s\0", $1,$2,$3,$4}' "$ALL_HISTORY_FILE"
    elif [ "$directory" = "/" ]
    then gawk -vdirectory="$directory" -vstart_time="$start_time" -vend_time="$end_time" -vsearch="$search" -vhost="$host" -vuser="$user" \
      'BEGIN { RS="\0"; FS="\t"; user_matcher="^"user"(@|$)"; host_matcher="[^@]*@"host;}
       { for(i = 5; i <= NF; i++) $4 = $4 "\t" $i}
       { if((length(start_time) == 0 || $3 >= start_time) &&
            (length(end_time) == 0 || $3 <= end_time) &&
            (length(user) == 0 || $1 ~ user_matcher ) &&
            (length(host) == 0 || $1 ~ host_matcher ) &&
            (length(search) == 0 || $4 ~ search )) printf "%s\t%s\t%s\t%s\0", $1,$2,$3,$4}' "$ALL_HISTORY_FILE"
    else gawk -vdirectory="$directory" -vstart_time="$start_time" -vend_time="$end_time" -vsearch="$search" -vhost="$host" -vuser="$user" \
      'BEGIN { RS="\0"; FS="\t"; user_matcher="^"user"(@|$)"; host_matcher="[^@]*@"host;}
       { for(i = 5; i <= NF; i++) $4 = $4 "\t" $i}
       index($2,directory) == 1 {
           if((length(start_time) == 0 || $3 >= start_time) &&
              (length(end_time) == 0 || $3 <= end_time) &&
              (length(user) == 0 || $1 ~ user_matcher ) &&
              (length(host) == 0 || $1 ~ host_matcher ) &&
              (length(search) == 0 || $4 ~ search )) printf "%s\t%s\t%s\t%s\0", $1,$2,$3,$4}' "$ALL_HISTORY_FILE"
    fi
}
