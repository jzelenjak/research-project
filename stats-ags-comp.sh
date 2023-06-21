#!/bin/bash
# Computes statistics on two directories with attack graphs to compare them side-by-side.
# The computed statistics are (see also stats-ags.sh and stats-ag.sh scripts):
#   - Number of nodes, edges, simplicity, whether the AG is complex or not, the number of discovered objective variants (for each AG, see also stats-ag.sh script)
#     Format:  `graph_name \t num_nodes \t num_edges \t simplicity \t is_complex \t num_obj_variants`
#     Example: `10.0.0.1|NETWORK_DoS|ms-wbt-server            70        172  0.406977  Yes  3`
#   - Average number of nodes for all AGs in the directory
#   - Average number of edges for all AGs in the directory
#   - Average simplicity for all AGs in the directory
# For statistics per AG, which are put side-by-side, the (absolute) difference in node count, edge count, simplicity, complexity and the number of objective variants is also computed.
# Average statistics are simply put side-by-side.
#
# Output format and an example (everything is tab-separated):
# `ag_name,nodes1,edges1,simplicity1,is_complex1,obj_vars1,nodes2,edges2,simplicity2,is_complex2,obj_vars2,diff_nodes,diff_edges,diff_simplicity,diff_complexity,diff_obj_vars`
#
# `                       1                      2         3        4      5   6  7         8        9      10  11 12  13     14      15  16`
# `                      name                    n1        e1      s1      c1  o1 n2        e2      s2      c2  o2 d_n d_e    d_s     d_c d_o`
# `10.0.0.100|DATA_EXFILTRATION|microsoft-ds     42        95   0.442105  Yes  2  31        94   0.329787  Yes  1  11  1   0.112318  SAME  1`
#
# NB! Average statistics include all graphs in the directory, while the side-by-side ones are only produced for AGs that are present in both directories.
#
# NB! This script is based on .dot files, which are by default deleted during the execution of SAGE.
#      To prevent the deletion, set the DOCKER variable to False (in SAGE).

set -euo pipefail
IFS=$'\n\t'

umask 077

function usage(){
    echo -e "Usage: $0 path/to/original/AGs path/to/modified/AGs/ [ n | nodes | e | edges | s | simplicity | o | objectives ]\n
        [ n | nodes | e | edges | s | simplicity | o | objectives ]\tsort by the difference in nodes, edges, simplicity and objective variants, respectively"
}

# Check if at least two arguments are provided
[[ $# -lt 2 ]] && { usage >&2 ; exit 1; }

# Check if all input directories exist
original=$(echo "$1/" | tr -s '/')
modified=$(echo "$2/" | tr -s '/')
! [[ -d "$original" ]] && { echo "$0: directory $original does not exist" >&2 ; exit 1 ; }
! [[ -d "$modified" ]] && { echo "$0: directory $modified does not exist" >&2 ; exit 1 ; }

# Infer the sorting parameter (default: diff_nodes)
# NB! `n` is needed, as it is numeric sort for integers (and will take precedence over the `g` option used later in this script
#     Simplicity is a decimal, not integer, so no `n` option is used
sort_by=12n
if [[ "$#" -eq 3 ]]; then
    case "$3" in
        "nodes" | "n") sort_by=12n ;;
        "edges" | "e") sort_by=13n ;;
        "simplicity" | "s") sort_by=14 ;;
        "objectives" | "o") sort_by=16n ;;
        *) { usage >&2 ; exit 1; } ;;
    esac
fi

# Output format (same as above, but duplicated here for easier reference):
#                        1                      2         3        4      5   6  7         8        9      10  11 12  13     14      15  16
#                       name                    n1        e1      s1      c1  o1 n2        e2      s2      c2  o2 d_n d_e    d_s     d_c d_o
# 10.0.0.100|DATA_EXFILTRATION|microsoft-ds     42        95   0.442105  Yes  2  31        94   0.329787  Yes  1  11  1   0.112318  SAME  1

# Uncomment the next line if you want to print the the column names. Note: do not forget to comment out this line when piping statistics to `wc` (e.g. ` ... | wc -l`)
# echo "ag_name,nodes1,edges1,simplicity1,is_complex1,obj_vars1,nodes2,edges2,simplicity2,is_complex2,obj_vars2,diff_nodes,diff_edges,diff_simplicity,diff_complexity,diff_obj_vars"

script="./stats-ags.sh"
# Because this is an inner join, averages have to be preserved, since the number of AGs in each directory before the join might be different
# First, get rid of the "pretty" output format of stats-ags.sh script and sort the graphs based on their names (required by the `join` command)
join -t $'\t' -j 1 \
    <("$script" "$original" "$modified" | sed 's/Average /Average@/' | sed 's/ count/@count/' | awk '{ print $1 "\t" $2 "\t" $3 "\t" $4 "\t" $5 "\t" $6 }' | tr '@' ' ' | sort -t $'\t' -k 1,1) \
    <("$script" "$modified" "$original" | sed 's/Average /Average@/' | sed 's/ count/@count/' | awk '{ print $1 "\t" $2 "\t" $3 "\t" $4 "\t" $5 "\t" $6 }' | tr '@' ' ' | sort -t $'\t' -k 1,1) |
    awk -F '\t' '                                                                                                           # Combine the statistics for matching AGs
        function abs(x) { return x < 0 ? -x : x; }                                                                          # Function to compute the absolute value
        function diff_complexity(c1,c2) { return c1 != c2 ? "DIFF" : "SAME"; }                                              # Function to compare the complexity of the graphs

        /Average/ { print $0 };                                                                                             # For lines with average statistics, simply print the line
        !/Average/ {                                                                                                        # For lines with AGs, append the differences (as described above)
            print $0 "\t" abs($2 - $7) "\t" abs($3 - $8) "\t" abs($4 - $9) "\t" diff_complexity($5,$10) "\t" abs($6 - $11)
        }' |
    # Below are the filters to analyse the computed statistics. Uncomment the ones you need
    # NB! Be careful: if filters are used incorrectly (e.g. incompatible filters), the results might be incorrect
    # grep -v 'Average' |                                                            # Exclude average statistics
    # The following are the filters for the 'size' statistics
    # awk -F '\t' '$2 < $7 { print }' |                                              # Increase in node count
    # awk -F '\t' '$2 > $7 { print }' |                                              # Decrease in node count
    # awk -F '\t' '$2 == $7 { print }' |                                             # Same node count
    # sort -t $'\t' -k2,2nr |                                                        # Sort (decreasingly) by the number of nodes in the original SAGE
    # sort -t $'\t' -k7,7nr |                                                        # Sort (decreasingly) by the number of nodes in the modified SAGE
    # The following are the filters for the 'complexity' statistics
    # awk -F '\t' '$5 == "Yes" { print }' |                                          # Only complex graphs for the original algorithm
    # awk -F '\t' '$10 == "Yes" { print }' |                                         # Only complex graphs for the modified algorithm
    # awk -F '\t' '$5 == "No" { print }' |                                           # Only not complex graphs for the original algorithm
    # awk -F '\t' '$10 == "No" { print }' |                                          # Only not complex graphs for the modified algorithm
    # awk -F '\t' '$5 == "Yes" && $10 == "No" { print }' |                           # Only graphs that became not complex
    # awk -F '\t' '$5 == "No" && $10 == "Yes" { print }' |                           # Only graphs that became complex
    # awk -F '\t' '$5 != $10 { print }' |                                            # Only graphs that have changed their complexity
    # awk -F '\t' '$5 == $10 { print }' |                                            # Only graphs that have not changed their complexity
    # Other filters and pipelines
    # awk '$2 != $7 || $3 != $8 || $4 != $9 || $5 != $10 || $6 != $11 { print }' |   # Only graphs with at least one different statistic
    # awk -F '\t' '$13 != $16 { print }' |                                           # Only graphs for which the difference in edge count is not the same as the difference in the number objective variants (this should not occur)
    sort -t $'\t' -g -k${sort_by},${sort_by}r |                                    # field_start[type][,field_end[type]] NB! By default it sorts by difference in node count (for other options, see above)
    # tr $'\t' ','                                                                   # Separate fields with commas instead of tabs (e.g. when writing the resulting statistics to a csv file)
    column -t -s $'\t'                                                             # Make the output aligned (see https://unix.stackexchange.com/questions/7698/command-to-layout-tab-separated-list-nicely)

