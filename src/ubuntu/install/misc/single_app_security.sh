#!/usr/bin/env bash
# Hardens a single-application Kasm desktop: removes terminals so users cannot
# break out of the browser into a shell.
# Usage: single_app_security.sh [-t]
#   -t  Remove terminal emulators

REMOVE_TERMINALS=false

while getopts "th" var
do
   case "$var" in
       t) REMOVE_TERMINALS=true;;
       h) echo "Valid arguments:"
          echo "-t    Remove terminals"
       ;;
   esac
done

## Remote unneeded packages

#Remove Terminals
if [ "$REMOVE_TERMINALS" = true ] ; then
    echo "Removing terminals..."
    if [ -x "$(command -v apt-get)" ]; then
        echo "apt package manager detected"
        terminals=("koi8rxterm" "lxterm" "xterm" "x-terminal-emulator" "xfce4-terminal" "xfce4-terminal.wrapper")

        for termapp in ${terminals[@]}; do
            if [[ $(apt -qq list "$termapp") ]] ; then
                echo "Removing termina all $termapp."
                apt remove -y ${termapp}
            fi
        done
    fi
fi