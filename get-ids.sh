#!/bin/bash
# Gets all node IDs for a specific node (e.g. `mcat|mserv`) from a directory with attack graphs.
# The output is sorted and does not contain duplicates. 
#
# Example usage: `./get-ids.sh orig-2017AGs/ "DATA EXFILTRATION|unknown"`
# Example output:
#   DATA EXFILTRATION|unknown | ID: 190 (sink)
#   DATA EXFILTRATION|unknown | ID: 369 (sink)
#   DATA EXFILTRATION|unknown | ID: 418 (sink)
#   DATA EXFILTRATION|unknown | ID: 422 (sink)
#   DATA EXFILTRATION|unknown | ID: 50 (non-sink)
#
# If you want to list all nodes with their IDs, you can run `./get-ids.sh orig-2017AGs/ ""` (`grep` will match everything)
#
# NB! This script is based on .dot files, which are by default deleted during the execution of SAGE.
#      To prevent the deletion, set the DOCKER variable to False (in SAGE).

set -euo pipefail
IFS=$'\n\t'

umask 077

function usage(){
    echo "Usage: $0 path/to/AGs 'mcat'"
}

# Check if exactly two arguments are provided
[[ $# -ne 2 ]] && { usage >&2 ; exit 1; }

# Take all the .dot files from the provided directory and get their names, IDs and whether they are sinks
find "$1" -type f -name '*.dot' | 
    xargs gvpr '
        N {
            string sink = "non-sink";
            if (index($.style, "dotted") != -1) sink = "sink";                  // Check if it is a sink or not
            print(gsub(gsub($.name, "\r"), "\n", "|") + " (" + sink + ")");     // Put everything on one line 
        }' |
    grep -v "^Victim" |     # Remove the artificial root nodes (which start with "Victim: ")
    sort |                  # Sort the nodes based on their names and IDs
    uniq |                  # Remove duplicate nodes
    grep "$2"               # Filter only the ones which we are interested it

