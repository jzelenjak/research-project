#!/bin/bash
# Computes statistics on a directory with attack graphs.
# The computes statistics are:
#   - Number of nodes, edges and simplicity (complexity) for each AG
#   - Average number of nodes for all AGs in the directory
#   - Average number of edges for all AGs in the directory
#   - Average simplicity (complexity) for all AGs in the directory
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

DIR=$1

! [[ -d "$DIR" ]] && { echo "$0: directory $DIR does not exits" >&2 ; exit 1 ; }


find $DIR -type f -name '*.dot' |
    sed 's@^\(.*\)$@./get-nodes-edges.sh \1@' |
    sh |
    awk -F '\t' '{
            v += $(NF-2);
            e += $(NF-1);
            s += $NF
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

