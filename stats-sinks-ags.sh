#!/bin/bash
# Compares two directories with attack graphs in terms of sink and non-sink nodes.
# It performs a left outer join on nodes from two directories.
#   If a node is absent in the second directory, "-" will be written, which indicates that this node has been merged.
#   If a node is present in both directories, its status ("sink" or "non-sink") will be printed for both directories.
#
# Example output:
#   ARBITRARY CODE EXECUTION|microsoft-ds | ID: 1083    sink      -
#   ARBITRARY CODE EXECUTION|microsoft-ds | ID: 1097    sink      -
#   ARBITRARY CODE EXECUTION|microsoft-ds | ID: 11      sink      -
#   ARBITRARY CODE EXECUTION|microsoft-ds | ID: 288     non-sink  non-sink
#   ARBITRARY CODE EXECUTION|microsoft-ds | ID: 673     sink      -
#   ARBITRARY CODE EXECUTION|microsoft-ds | ID: 853     sink      -
#
# NB! This script is based on .dot files, which are by default deleted during the execution of SAGE.
#      To prevent the deletion, set the DOCKER variable to False (in SAGE).

set -euo pipefail
IFS=$'\n\t'

umask 077

function usage(){
    echo "Usage: $0 path/to/AGs path/to/AGs"
}

function get_states() {
    find "$1" -type f -name '*.dot' |                                   # Find all the .dot files in the provided directory
    xargs gvpr '
        N {
            string sink = "non-sink";
            if (index($.style, "dotted") != -1) sink = "sink";          // Check whether the node is a sink or a non-sink node
            print(gsub(gsub($.name, "\r"), "\n", "|") + "\t" + sink);   // Print everything on one line
        }' |
        grep -v '^Victim' |                                             # Remove the artificial root nodes (start with "Victim: ")
        sort -u -t $'\t' -k1,1                                          # Sort by name and ID, removing duplicate nodes
}

# Check if exactly two arguments are provided
[[ $# -ne 2 ]] && { usage >&2 ; exit 1; }

# Check if all input directories exist
original=$(echo "$1/" | tr -s '/')
modified=$(echo "$2/" | tr -s '/')
! [[ -d "$original" ]] && { echo "$0: directory $original does not exist" >&2 ; exit 1 ; }
! [[ -d "$modified" ]] && { echo "$0: directory $modified does not exist" >&2 ; exit 1 ; }

# Perform a left-outer join based on the node name and ID
join -t $'\t' -a1 -e "-" -o'0,1.2,2.2' <(get_states "$original") <(get_states "$modified") |    # Join nodes from both directories based on their names and IDs (first field, separated by '\t')
    column -t -s $'\t' #|                                                                       # Align tabs to produce better-looking output
    #awk '$(NF-1) == "sink" && $NF == "non-sink" { print }'                                     # Filter sink nodes that have become non-sinks
    #awk '$(NF-1) == "sink" && $NF == "-" { print }'                                            # Filter sink nodes that have been merged
    #awk '$(NF-1) == "non-sink" && $NF == "non-sink" { print }'                                 # Filter non-sink nodes that have remained after merging

