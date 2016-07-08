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


### SETTINGS ###

if [ -z "$ALL_HISTORY_FILE" ]
then
  ALL_HISTORY_FILE=~/.bash_all_history
fi

### END SETTINGS ###

# Check dependencies
if ! command -v gawk &> /dev/null; then
	printf '%s requires gawk\n' $BASH_SOURCE
fi
if date --date today &> /dev/null; then
  __BASH_HISTORY_GDATE=date
elif gdate --date today &> /dev/null; then
  __BASH_HISTORY_GDATE=gdate
else
  printf '%s requires GNU date\n' $BASH_SOURCE
fi


#set up history logging of commands
export HISTTIMEFORMAT='	%F %T	'
export HISTCONTROL='ignorespace'
PROMPT_COMMAND="${PROMPT_COMMAND}; _log_history"
_HISTNUM=""
_LAST_COMMAND=""
declare -a _PWD

# logging function
function _log_history {
local directory="$(pwd -P)"
local histnum="$(history 1 | sed 's/ *\([0-9]*\).*/\1/')"
if [ -z "$_HISTNUM" ]
then
 _HISTNUM="$histnum"
elif [ "$histnum" != "$_HISTNUM" ]
then
 if [ "$directory" != "$_PWD" ]
 then
  local match
  local i
  for i in {1..8}
  do if [ "$directory" = "${_PWD[$i]}" ]
     then unset _PWD[$i]
          match="true"
     fi
  done
  if [ -z "$match" ]
  then unset _PWD[9]
  fi
  _PWD=( "$directory" "${_PWD[@]}" )
  local directory="${_PWD[1]}"
 fi
 local command="$(cat <(history 1 | head -1 | sed 's/[^	]*	//') <(history 1 | tail -n +2))"
 printf '%q\t%q\t%s\n\x00' "$USER@$HOSTNAME" "$directory" "$command" >> "$ALL_HISTORY_FILE"
 if [ "$_LAST_COMMAND" = "$command" ]
 then
  history -d "$histnum"
 else
  _HISTNUM="$histnum"
  _LAST_COMMAND="$command"
 fi
fi
}

# history
h () {
  gawk_history_interactive "/" 1 "$@"
}

# history of commands run in this directory and subdirectories (with grep)
dh () {
  gawk_history_interactive "$(printf '%b' "$(pwd -P)")" 1 "$@"
}

# history of commands run in this directory only (with grep)
ldh () {
  gawk_history_interactive "$(printf '%b' "$(pwd -P)")" 0 "$@"
}

# select from history
h! () {
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

# select from working directory history
cd! () {
  local histline
  local history
  local item
  local line

  if [ -z "$*" ]
  then history=( "${_PWD[@]}" )
  else while read -r -d '' histline
    do history+=( "$histline" )
    done < <( gawk_directory_history "/" 1 "$@" )
  fi

  select item in "${history[@]}"
  do
      if [ -z "$item" ]
      then break
      fi

      # Read user edited command
      read -er -i "$item" -p '$ ' item
      while bash -n <<<$item 2>&1 | grep 'unexpected end of file' > /dev/null || [ -z "${item%%*\\}" ]
      do
        read -r -p '> ' line
        item="$item"$'\n'"$line"
      done

      # Add command to history and run
      history -s "cd $item"
      cd "$item"
      return $?
  done
}

# bash completions

complete -cf h
complete -cf dh
complete -cf ldh
complete -cf h!
complete -cf dh!
complete -cf ldh!

# select history implementation
select_history () {
  local histline
  local history
  local item
  local line

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

      # Read user edited command
      read -er -i "$item" -p '$ ' item
      while bash -n <<<$item 2>&1 | grep 'unexpected end of file' > /dev/null || [ -z "${item%%*\\}" ]
      do
        read -r -p '> ' line
        item="$item"$'\n'"$line"
      done

      # Add command to history and run
      history -s "$item"
      eval "$item"
      return $?
  done
}

# directory history implementation
gawk_directory_history () {
  gawk_history "$@" |
    gawk 'BEGIN { RS="\0"; FS="\t"; }
          { a[$2] = NR }
          END { PROCINFO["sorted_in"] = "@val_num_desc";
                num = 0;
                for (i in a) { printf "%s\0", i; num++; if (num == 10) break } }'
}

# interative gawk history implementation
gawk_history_interactive () {
    # read arguments
    local state="first"

    for arg in "$@"
    do
        if [ "$state" = "first" ]
        then
            state="second"
        elif [ "$state" = "second" ]
        then
            state=""
        elif [ "$arg" = "-h" -o "$arg" = "--help" ]
        then
            printf 'Usage: [[l]d]h[!] [CONTEXT] [TIMESPEC] [--] [SEARCH]
Search command history.

SEARCH is a regular expression understood by `gawk`
used to match the executed command.

TIMESPEC is an argument of the form "[START..END]",
where START and END are strings understood by `date`.
A single day may be specified by "[DATE]".

CONTEXT is an argument of the form "USER@HOST:DIRECTORY"
or "USER@HOST::DIRECTORY", where each field is optional.
"@" is used to specify user or host filters.
":" is used to specify a directory filter.
"::" may be used instead to exclude subdirectories.

Select from the 10 most recent matching entries
adding `!` to the command (ex. `h!`).
The selected command may be edited before execution.
'
            return 0
        fi
    done
    gawk_history "$@" | tr -d '\000' | less -FX +G
}

# core gawk history implementation
gawk_history () {
    # read arguments
    local state="first"
    local search
    local timespec
    local user
    local host
    local argdir
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
            search+="${arg}.*"
        elif [ "$state" = "time" ]
        then
            timespec="$timespec $arg"
            if [ -z "${arg/*]/}" ]
              then state=""
            fi
        elif [ "$arg" = "--" ]
          then state="input"
        elif [ -z "${arg/\[*/}" -a ! "$timespec" ]
        then
            timespec="$arg"
            if [ "${arg/*]/}" ]
              then state="time"
            fi
        elif [ -z "${arg/*@*/}" -o -z "${arg/*:*/}" ]
        then
            if [ -z "${arg/*@*/}" ]
            then
              if [ "${arg%%@*}" -a ! "$user" ]
              then
                user="${arg%%@*}" 
              fi
              if [ "${arg#*@}" -a ! "$host" ]
              then
                host="${arg#*@}"
                host="${host%%:*}"
              fi
            fi
            if [ -z "${arg/*::*/}" ]
            then
              if [ "${arg#*::}" -a ! "$argdir" ]
              then
                argdir="${arg#*::}"
                recursive_dir=0
              fi
            elif [ -z "${arg/*:*/}" ]
            then
              if [ "${arg#*:}" -a ! "$argdir" ]
              then
                argdir="${arg#*:}"
                recursive_dir=1
              fi
            fi
        else
            search+="${arg}.*"
        fi
    done

    if [ "$argdir" ]
    then
        if [ -z "${argdir##~*}" ]
        then directory="$(readlink -m -- "$HOME${argdir#\~}")"
        else directory="$(readlink -m -- "$argdir")"
        fi
    fi

    local start_time
    local end_time
    if [ "${timespec/*..*/}" ]
    then
      timespec="${timespec#[}"
      timespec="$($__BASH_HISTORY_GDATE -d "${timespec%]}" '+%F')"
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
      start_time="$($__BASH_HISTORY_GDATE -d "$start_time" '+%F %T')"
      if [ -z "$start_time" ]
      then
        return 1
      fi
    fi
    if [ "$end_time" ]
    then
      end_time="$($__BASH_HISTORY_GDATE -d "$end_time" '+%F %T')"
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

_init_log_history () {
  local histline
  while read -r -d '' histline
  do _PWD+=( "$histline" )
  done < <( gawk 'BEGIN { RS="\0"; FS="\t"; }
                  { a[$2] = NR }
                  END { PROCINFO["sorted_in"] = "@val_num_desc";
                        num = 0;
                        for (i in a) { printf "%s\0", i; num++; if (num == 10) break } }' \
                  "$ALL_HISTORY_FILE" )

  local directory="$(pwd -P)"
  if [ "$directory" != "$_PWD" ]
  then
    local match
    local i
    for i in {1..8}
    do if [ "$directory" = "${_PWD[$i]}" ]
       then unset _PWD[$i]
            match="true"
       fi
    done
    if [ -z "$match" ]
    then unset _PWD[9]
    fi
    _PWD=( "$directory" "${_PWD[@]}" )
    local directory="${_PWD[1]}"
  fi
}
_init_log_history
