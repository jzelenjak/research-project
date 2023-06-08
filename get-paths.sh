#!/bin/bash
# Parses the edges from (an) AG(s) to create attack paths for (attacker,victim,objective) triple
#
# NB! The comparison is based on .dot files, which are by default deleted during the execution of SAGE.
#      To prevent this deletion, set DOCKER to False.

set -euo pipefail
IFS=$'\n\t'

umask 077

usage() {
    echo -e "Usage: $0 (ag.dot | AGs/)"
}

[[ $# -ne 1 ]] && { usage >&2 ; exit 1 ; }


if [[ -f "$1" ]] && [[ "${1##*.}" == "dot" ]]; then
    sed 's/\]$/]KIRIL/g' "$1" |
        sed 's/}$/}KIRIL/' |
        tr -d '\r' |
        tr '\n' ' ' |
        sed 's/KIRIL/\n/g' |
        grep -- '->' |
        sed 's/^ //' |
        sed 's/^\(.*start_next: \?\([0-9/,: -]\+\).*gap: -\?[0-9]\+sec.*end_prev: \?\([0-9/,: -]\+\).*\)$/\2\t\3\t\1/' |
        sed 's/^\(.*Attacker: \([0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+\).*\)$/\2\t\1/' |
        sed 's/\[.*\]//g' |
        sed 's/ | ID: -\?[0-9]\+//g' |
        tr -d '"' |
        awk -F '\t' 'NF == 3 { print "\t" $0 } NF == 4 { print $0 }' |
        awk -F '\t' 'BEGIN { current_attacker = ""; } $1 != "" { current_attacker = $1; print "\n" $0 } $1 == "" { print current_attacker "\t" $2 "\t" $3 "\t" $4 }' |
        sed '1d'
elif [[ -d "$1" ]]; then
    find "$1" -type f -name '*.dot' | sed 's@^\(.*\)$@'"$0"' \1 ; echo -e "\\n"@' | sh
else
    usage >&2
    exit 1
fi
