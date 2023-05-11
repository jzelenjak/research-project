#!/bin/bash
# Computes statistics on two directories with attack graphs to compare them side-by-side
# The computed statistics are:
#   - Number of nodes, edges, simplicity (complexity) and the number of discovered objective variants for each AG in each directory
#     Format: (graph_name, num_nodes, num_edges, simplicity, num_obj_variants)
#   - Average number of nodes for all AGs in each directory
#   - Average number of edges for all AGs in each directory
#   - Average simplicity (complexity) for all AGs in each directory
# NB! Average statistics include all graphs in the directory, while side-by-side ones are only produced for AGs that are in both directories
#
# NB! The comparison is based on .dot files, which are by default deleted during the execution of SAGE
#      To prevent deletion, comment out lines 2850-2851 in sage.py
#     In addition, the filenames of the generated AGs have to be the same, so I would recommend running SAGE both times with the same experiment name,
#      and then move the generated AGs from the directory ExpNameAGs/ into e.g. directories ExpName-origAGs/ and ExpName-modifiedAGs/ respectively

set -euo pipefail
IFS=$'\n\t'

umask 077

usage="usage: $0 path/to/original/AGs path/to/modified/AGs/"

[[ $# -ne 2 ]] && { echo $usage >&2 ; exit 1; }

ORIGINAL=$(echo $1/ | tr -s '/')
MODIFIED=$(echo $2/ | tr -s '/')

! [[ -d "$ORIGINAL" ]] && { echo "$0: directory $ORIGINAL does not exits" >&2 ; exit 1 ; }
! [[ -d "$MODIFIED" ]] && { echo "$0: directory $MODIFIED does not exits" >&2 ; exit 1 ; }

SCRIPT="./stats-ags.sh"

echo "                      name                    n1       e1    simp1  sub1 n2        e2     simp2  sub2"

# Because this is an inner join, averages have to be preserved, since the number of AGs before the join might be different
join -t $'\t' -j 1 \
    <("$SCRIPT" "$ORIGINAL" | grep -v -- '-----' | sed 's/Average /Average@/' | sed 's/ count/@count/' | awk '{ print $1 "\t" $2 "\t" $3 "\t" $4 "\t" $5 }' | tr '@' ' ' | sort -t $'\t' -k 1,1) \
    <("$SCRIPT" "$MODIFIED" | grep -v -- '-----' | sed 's/Average /Average@/' | sed 's/ count/@count/' | awk '{ print $1 "\t" $2 "\t" $3 "\t" $4 "\t" $5 }' | tr '@' ' ' | sort -t $'\t' -k 1,1) |
    awk -F '\t' '{ print $0 "\t" ($4 < $8 ? $8 - $4 : $4 - $8) }' |
    sort -t $'\t' -g -k10,10r |  # field_start[type][,field_end[type]]
    sed 's/^\(Average .*\)0$/\1/' |
    column -t -s $'\t'

#                       1                      2        3       4     5   6         7        8     9   diff_n
#                      name                    n1       e1    simp1  sub1 n2        e2     simp2  sub2
#10.0.99.143|DATA_EXFILTRATION|vrml-multi-use  14       27   0.518519  1  13        27   0.481481  1  0.037038
#10.0.0.100|DATA_EXFILTRATION|microsoft-ds     47       97   0.484536  4  32        94   0.340426  1  0.14411
