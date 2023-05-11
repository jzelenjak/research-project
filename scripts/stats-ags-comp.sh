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

SCRIPT="./stats-ags.sh"

[[ $# -lt 2 ]] && { echo $usage >&2 ; exit 1; }

ORIGINAL=$(echo "$1/" | tr -s '/')
MODIFIED=$(echo "$2/" | tr -s '/')

! [[ -d "$ORIGINAL" ]] && { echo "$0: directory $ORIGINAL does not exits" >&2 ; exit 1 ; }
! [[ -d "$MODIFIED" ]] && { echo "$0: directory $MODIFIED does not exits" >&2 ; exit 1 ; }

# Infer the sorting parameter (default: simplicity)
SORT_BY=12
if [[ "$#" -eq 3 ]]; then
    case "$3" in
        "nodes" | "n") SORT_BY=10n ;;
        "edges" | "e") SORT_BY=11n ;;
        "simplicity" | "s") SORT_BY=12 ;;
        "objectives" | "o") SORT_BY=13n ;;
        *) { echo -e "$0: invalid option for sort\nAvailable options: n(odes), e(dges), s(implicity), o(bjectives)" >&2 ; exit 1; } ;;
    esac
fi

echo "                      name                    n1       e1      s1    o1  n2        e2      s2    o2 d_n d_e    d_s    d_o"

# Because this is an inner join, averages have to be preserved, since the number of AGs before the join might be different
join -t $'\t' -j 1 \
    <("$SCRIPT" "$ORIGINAL" | grep -v -- '-----' | sed 's/Average /Average@/' | sed 's/ count/@count/' | awk '{ print $1 "\t" $2 "\t" $3 "\t" $4 "\t" $5 }' | tr '@' ' ' | sort -t $'\t' -k 1,1) \
    <("$SCRIPT" "$MODIFIED" | grep -v -- '-----' | sed 's/Average /Average@/' | sed 's/ count/@count/' | awk '{ print $1 "\t" $2 "\t" $3 "\t" $4 "\t" $5 }' | tr '@' ' ' | sort -t $'\t' -k 1,1) |
    awk -F '\t' '
        function abs(x) { return x < 0 ? -x : x; }
        /Average/ { print $0 };
        !/Average/ { print $0 "\t" abs($2 - $6) "\t" abs($3 - $7) "\t" abs($4 - $8) "\t" abs($5 - $9) }' |
    sort -t $'\t' -g -k${SORT_BY},${SORT_BY}r |  # field_start[type][,field_end[type]]
    column -t -s $'\t'

#                       1                      2        3        4     5   6         7       8     9  10  11    12     13
#                      name                    n1       e1      s1    o1  n2        e2      s2    o2 d_n d_e    d_s    d_o
#10.0.0.100|NETWORK_DoS|ssdp                   13       15   0.866667  1  22        42   0.52381   1  9   27  0.342857  0
#10.0.0.101|DATA_EXFILTRATION|http             42       69   0.608696  3  33        68   0.485294  2  9   1   0.123402  1

