#!/bin/bash
# Computes statistics on a directory with attack graphs.
# The computed statistics are:
#   - Number of nodes, edges, simplicity (complexity) and the number of discovered objective variants for each AG
#     Format: (graph_name, num_nodes, num_edges, simplicity, num_obj_variants)
#   - Average number of nodes for all AGs in the directory
#   - Average number of edges for all AGs in the directory
#   - Average simplicity (complexity) for all AGs in the directory
# Output format:
#
# NB! The comparison is based on .dot files, which are by default deleted during the execution of SAGE
#      To prevent deletion, comment out lines 2850-2851 in sage.py
#     In addition, the filenames of the generated AGs have to be the same, so I would recommend running SAGE both times with the same experiment name,
#      and then move the generated AGs from the directory ExpNameAGs/ into e.g. directories ExpName-origAGs/ and ExpName-modifiedAGs/ respectively

set -euo pipefail
IFS=$'\n\t'

umask 077

usage="usage: $0 path/to/AGs"

[[ $# -ne 1 ]] && { echo $usage >&2 ; exit 1; }

DIR=$(echo "$1/" | tr -s '/')

! [[ -d "$DIR" ]] && { echo "$0: directory $DIR does not exits" >&2 ; exit 1 ; }

SCRIPT="./stats-ag.sh"

find $DIR -type f -name '*.dot' |
    sed 's@^\(.*\)$@'$SCRIPT' \1@' |
    sh |
    awk -F '\t' '{
            v += $2;
            e += $3;
            s += $4;
            count += 1;
            print($0)
        }

        END {
            print("-----");
            print("Average node count:\t" v / count);
            print("Average edge count:\t" e / count);
            print("Average simplicity:\t" s / count);
        }' |
     column -t -s $'\t' # `-t` splits columns at any whitespace; to set the delimiter to tabs only: `-t -s $'\t'` (see https://unix.stackexchange.com/questions/7698/command-to-layout-tab-separated-list-nicely)

