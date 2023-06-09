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


# If the input is a single AG
if [[ -f "$1" ]] && [[ "${1##*.}" == "dot" ]]; then
    ag_name=$(grep -A 2 '^"Victim: [0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+' "$1" | head -3 | tr '\n' '|' | sed 's/\[.*//g' | tr -d '"' | sed 's/Victim: //')  # Carefully parse the AG name...
    echo "$ag_name"
    victim=$(sed 's/|.*$//' <<< "$ag_name")  # Get the victim from the first line of the AG name

    # This is the oracle used for testing purposes. 
    # expected=$(gvpr 'BEG_G { int obj_vars = 0; } N [ $.shape == "hexagon" && $.fillcolor == "salmon" ] { obj_vars += 1; } END_G { print(nEdges($G) - obj_vars); }' "$1")
    # actual=$(<paste the pipeline below> | grep -- '->' | wc -l)
    # [[ "$actual" -eq "$expected" ]] && echo "Passed" || echo -e "org.opentest4j.AssertionFailedError: expected <$expected> but was <$actual>" >&2

    sed 's/\]$/]KIRIL/g' "$1" |  # Put a special "identifier" at the end of the line which represents an edge (excluding the edges from the objective variants to the objective node)
        sed 's/}$/}KIRIL/' |     # Same, but for other unnecessary lines (they will be removed later in the parsing)
        tr -d '\r' |             # Remove \r because some people use the wrong OS
        tr '\n' ' ' |            # Remove all newlines (to be precise, replace them with spaces, so that everything is on one line)
        sed 's/KIRIL/\n/g' |     # Put "chunks" (among which will be the edges that we need) on each line
        grep -- '->' |           # From all "chunks", select only the edges (i.e. lines that have `->`)
        sed 's/^ //' |           # Remove redundant leading whitespaces
        sed 's/^\(.*start_next: \?\([0-9/,: -]\+\).*gap: -\?[0-9]\+sec.*end_prev: \?\([0-9/,: -]\+\).*\)$/\3\t\2\t\1/' |  # Put the timestamps at the beginning of the line (end_prev, start_next)
        sed 's/^\(.*Attacker: \([0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+\).*\)$/\2\t\1/' |                                      # Put the attacker IP at the beginning of the line, if it is present
        sed 's/\[.*\]//g' |      # Remove all the unnecessary metadata (attributes of the edges, they are no longer needed)
        sed 's/ | ID: -\?[0-9]\+//g' |  # Remove node IDs: they are not really needed (though, feel free to comment out this line if you need them)
        tr -d '"' |              # Remove quotation marks for the edge endpoints
        awk -F '\t' 'NF == 3 { print "\t" $0 } NF == 4 { print $0 }' |  # Make every line have four tab-separated fields (if the attacker is not present, the first field will be empty)
        awk -F '\t' 'BEGIN {
            current_attacker = "";
        }
        $1 != "" {
            current_attacker = $1;
            print "\n" $1 "\t" "'"$victim"'" "\t" $2 "\t" $3 "\t" $4
        }
        $1 == "" {
            print current_attacker "\t" "'"$victim"'" "\t" $2 "\t" $3 "\t" $4
        }'                       # Paste the attacker IP for each attack path (use the current attacker until it changes (i.e. is present again)). In addition, add the victim IP
    echo "----------------------------------"  # This is just a separator, feel free to comment it out
# If the input is a directory with AGs
elif [[ -d "$1" ]]; then
    find "$1" -type f -name '*.dot' |               # Find all the .dot files
    sed 's@^\(.*\)$@'"$0"' \1 ; echo -ne "\\n"@' |   # Write a command to (recursively) run this script for each AG in the input directory
    sh                                              # Pipe the command to shell to be executed
else
    usage >&2
    exit 1
fi
