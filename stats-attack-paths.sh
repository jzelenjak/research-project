#!/bin/bash
# Gets the total number of attack paths for a single attack graph.
#   If multiple AGs are provided, then they are processed in turn.
# An attack path is an incoming edge to an objective variant (i.e. a hexagon node with salmon colour).
#
# If a directory is provided, the number of attack paths is computed for each AG in the directory (i.e. for each .dot file).
#
# If two directories are provided, the number of attack paths is computed for all AGs in each directory and a diff is taken.
#   - If the number of attack paths is the same for each corresponding pair of AGs, nothing is printed
#   - If the number of attack paths is not the same for at least one corresponding pair of AGs, the regular `diff` output is printed
#
# NB! This script is based on .dot files, which are by default deleted during the execution of SAGE.
#      To prevent the deletion, use the --keep-files option when running SAGE.

set -euo pipefail
IFS=$'\n\t'

umask 077

function usage(){
    echo -e "Usage: $0 path/to/AG.dot...\n       $0 path/to/AGs/\n       $0 path/to/original/AGs/ path/to/modified/AGs/"
}

# Check if at least one argument is provided
[[ $# -lt 1 ]] && { usage >&2 ; exit 1; }

# If a single directory is provided, recursively run the script on every .dot file
if [[ -d "$1" ]] && [[ $# -eq 1 ]]; then
    directory=$(echo "$1/" | tr -s '/')
    find "$directory" -type f -name '*.dot' | xargs "$0" | sort
# If two directories are provided, recursively run the script on every .dot file in each directory and take a diff
elif [[ -d "$1" ]] && [[ $# -eq 2 ]] && [[ -d "$2" ]]; then
    original=$(echo "$1/" | tr -s '/')
    modified=$(echo "$2/" | tr -s '/')

    diff <(find "$original" -type f -name '*.dot' | xargs "$0" | sort)\
         <(find "$modified" -type f -name '*.dot' | xargs "$0" | sort)
# Process each .dot file in turn
else
    # Check that all input arguments are .dot files
    for file in $*; do
        [[ -d "$file" ]] && { usage >&2 ; exit 1 ; }
        ! [[ -f "$file" ]] && { echo "$0: file $file does not exist" >&2 ; exit 1 ; }
        ! [[ "${file##*.}" == "dot" ]] && { echo "$0: file $file is not a .dot file" >&2 ; exit 1 ; }
    done

    # Get the AG name and the number of attack paths for this AG (i.e. total number of incoming edges to all objective variants)
    gvpr '
        BEG_G { int in_edges = 0; }
        
        N [ $.shape == "doubleoctagon" ] {                                                  // This is the root node, which contains the AG name
            string oneline = gsub(gsub($.name, "\r"), "\n", "|");                           // Put graph name on one line
            string graph_name = gsub(gsub(oneline, "Victim: "), " ", "_");                  // Remove the "Victim: " prefix and replace spaces with underscores
        }

        N [ $.shape == "hexagon" && fillcolor == "salmon" ] { in_edges += $.indegree; }     // This is an objective variant

        END_G {                                                                             
            print(graph_name, ": ", in_edges);                                              // Print the AG name and the number of attack paths
        }' $*
fi

