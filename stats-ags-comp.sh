#!/bin/bash
# Computes statistics on two directories with attack graphs to compare them side-by-side
# The computed statistics are:
#   - Number of nodes, edges, simplicity (complexity), whether the AG is complex or not, the number of discovered objective variants (for each AG in each directory)
#     Format: (graph_name, num_nodes, num_edges, simplicity, is_complex, num_obj_variants)
#   - Average number of nodes for all AGs in each directory
#   - Average number of edges for all AGs in each directory
#   - Average simplicity (complexity) for all AGs in each directory
# NB! Average statistics include all graphs in the directory, while side-by-side ones are only produced for AGs that are in both directories
#
# NB! The comparison is based on .dot files, which are by default deleted during the execution of SAGE
#      To prevent deletion, comment out lines 2850-2851 in sage.py

set -euo pipefail
IFS=$'\n\t'

umask 077

usage="usage: $0 path/to/original/AGs path/to/modified/AGs/"

script="./stats-ags.sh"

[[ $# -lt 2 ]] && { echo $usage >&2 ; exit 1; }

original=$(echo "$1/" | tr -s '/')
modified=$(echo "$2/" | tr -s '/')

! [[ -d "$original" ]] && { echo "$0: directory $original does not exist" >&2 ; exit 1 ; }
! [[ -d "$modified" ]] && { echo "$0: directory $modified does not exist" >&2 ; exit 1 ; }

# Infer the sorting parameter (default: diff_nodes)
sort_by=12n
if [[ "$#" -eq 3 ]]; then
    case "$3" in
        "nodes" | "n") sort_by=12n ;;
        "edges" | "e") sort_by=13n ;;
        "simplicity" | "s") sort_by=14 ;;
        "objectives" | "o") sort_by=16n ;;
        *) { echo -e "$0: invalid option for sort\nAvailable options: n(odes), e(dges), s(implicity), o(bjectives)" >&2 ; exit 1; } ;;
    esac
fi

#echo "                      name                    n1        e1      s1      c1  o1 n2        e2      s2      c2  o2 d_n d_e    d_s     d_c d_o"

# Because this is an inner join, averages have to be preserved, since the number of AGs before the join might be different
join -t $'\t' -j 1 \
    <("$script" "$original" "$modified" | sed 's/Average /Average@/' | sed 's/ count/@count/' | awk '{ print $1 "\t" $2 "\t" $3 "\t" $4 "\t" $5 "\t" $6 }' | tr '@' ' ' | sort -t $'\t' -k 1,1) \
    <("$script" "$modified" "$original" | sed 's/Average /Average@/' | sed 's/ count/@count/' |  awk '{ print $1 "\t" $2 "\t" $3 "\t" $4 "\t" $5 "\t" $6 }' | tr '@' ' ' | sort -t $'\t' -k 1,1) |
    awk -F '\t' '
        function abs(x) { return x < 0 ? -x : x; }
        function diff_complexity(c1,c2) { return c1 != c2 ? "DIFF" : "SAME"; }
        /Average/ { print $0 };
        !/Average/ { print $0 "\t" abs($2 - $7) "\t" abs($3 - $8) "\t" abs($4 - $9) "\t" diff_complexity($5,$10) "\t" abs($6 - $11) }' |
    #grep -v 'Average' | # Exclude average statistics
    #awk '$2 < $7 { print }' | # Increase in node count
    #awk '$2 > $7 { print }' | # Decrease in node count
    #awk '$2 == $7 { print }' | # Same node count
    #sort -t $'\t' -k2,2nr | # Sort (decreasingly) by the number of nodes in the original SAGE
    #sort -t $'\t' -k7,7nr | # Sort (decreasingly) by the number of nodes in the modified SAGE
    #awk -F '\t' '$5 == "Yes" { print }' | # Only complex graphs for the original algorithm
    #awk -F '\t' '$10 == "Yes" { print }' | # Only complex graphs for the modified algorithm
    #awk -F '\t' '$5 == "No" { print }' | # Only not complex graphs for the original algorithm
    #awk -F '\t' '$10 == "No" { print }' | # Only not complex graphs for the modified algorithm
    #awk -F '\t' '$5 == "Yes" && $10 == "No" { print }' | # Only graphs that became not complex
    #awk -F '\t' '$5 == "No" && $10 == "Yes" { print }' | # Only graphs that became complex
    #awk -F '\t' '$5 == $10 { print }' | # Only graphs that have not changed their complexity
    #awk '$2 != $7 || $3 != $8 || $4 != $9 || $5 != $10 || $6 != $11 { print }' | # Different attack graph stats
    sort -t $'\t' -g -k${sort_by},${sort_by}r |  # field_start[type][,field_end[type]]
    column -t -s $'\t'

# Output format
#                       1                      2         3        4      5   6  7         8        9      10  11 12  13     14      15  16
#                      name                    n1        e1      s1      c1  o1 n2        e2      s2      c2  o2 d_n d_e    d_s     d_c d_o
#10.0.0.100|DATA_EXFILTRATION|microsoft-ds     42        95   0.442105  Yes  2  31        94   0.329787  Yes  1  11  1   0.112318  SAME  1
