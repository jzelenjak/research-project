#!/bin/bash
# Computes statistics on a directory with attack graphs.
# The computed statistics are:
#   - Number of nodes, edges, simplicity, whether the AG is complex or not, the number of discovered objective variants (for each AG)
#     Format: graph_name, num_nodes, num_edges, simplicity, is_complex, num_obj_variants
#     Example: 10.0.0.1|NETWORK_DoS|ms-wbt-server            70        172  0.406977  Yes  3
#   - Average number of nodes for all AGs in the directory
#   - Average number of edges for all AGs in the directory
#   - Average simplicity for all AGs in the directory
#
# Note: to train the linear regression model, one or more directories with AGs may be provided.
#     The statistics are in either case computed only for the first directory
# The approach of classifying graphs as complex or not is taken from the following paper:
#     Sean Carlisto De Alvarenga, Alessandro Ulrici, Rodrigo Sanches Miani, Michel Cukier, and Bruno Bogaz Zarpel ̃ao.
#     Process mining and hierarchical clustering to help intrusion alert visualization. Computers Security, 73:474–491, 3 2018
#
# NB! The comparison is based on .dot files, which are by default deleted during the execution of SAGE
#      To prevent deletion, comment out lines 2850-2851 in sage.py, or set DOCKER to False

set -euo pipefail
IFS=$'\n\t'

umask 077

usage="usage: $0 path/to/main/AGs [path/to/other/AGs...]"

[[ $# -lt 1 ]] && { echo $usage >&2 ; exit 1; }

for dir in $*; do
    ! [[ -d "$dir" ]] && { echo "$0: directory $dir does not exist" >&2 ; exit 1 ; }
done

SCRIPT_LIN_REG="./train-lin-reg.sh"
! [[ -f "$SCRIPT_LIN_REG" ]] && { echo "$0: file $SCRIPT_LIN_REG does not exist" >&2 ; exit 1 ; }

# Use precomputed results to avoid recomputing them on every run
# Comment out the if statements and uncomment the next line to compute the LR line on every run
# IFS=" " read A B vmin vmax <<<$($SCRIPT_LIN_REG $*)
if [[ "$1" =~ "orig-2017AGs" ]] && [[ $# -eq 2 ]] && [[ "$2" =~ "merged-sinks-2017AGs" ]]; then A=1.04007 ; B=-0.0153311 ; vmin=15 ; vmax=30 ;
elif [[ "$1" =~ "orig-2018AGs" ]] && [[ $# -eq 2 ]] && [[ "$2" =~ "merged-sinks-2018AGs" ]]; then A=1.07881 ; B=-0.0273639 ; vmin=15 ; vmax=30 ;
elif [[ "$1" =~ "orig-2017AGs" ]] && [[ $# -eq 1 ]]; then A=1.0402 ; B=-0.0140072 ; vmin=15 ; vmax=30 ;
elif [[ "$1" =~ "orig-2018AGs" ]] && [[ $# -eq 1 ]]; then A=0.990769 ; B=-0.0200832 vmin= ; vmin=15 ; vmax=30 ;
else IFS=" " read A B vmin vmax <<<$($SCRIPT_LIN_REG $*);
fi
# echo "Estimated linear regression parameters: $A $B $vmin $vmax"

SCRIPT="./stats-ag.sh"

find "$1" -type f -name '*.dot' |
    sed 's@^\(.*\)$@'$SCRIPT' \1@' |
    sh |
    awk -F '\t' '
        function is_complex(n,s) {
            ts = '"$A"' + '"$B"' * n;
            if (n < '"$vmin"') return "No";
            if (n > '"$vmax"') return "Yes";
            if (s >= ts) return "No";
            if (s < ts) return "Yes";
        }
        {
            v += $2;
            e += $3;
            s += $4;
            complex = is_complex($2,$4);
            count += 1;
            print($1 "\t" $2 "\t" $3 "\t" $4 "\t" complex "\t" $5);
        }
        END {
            print("Average node count:\t" v / count);
            print("Average edge count:\t" e / count);
            print("Average simplicity:\t" s / count);
        }' |
        column -t -s $'\t'

# `-t` splits columns at any whitespace; to set the delimiter to tabs only: `-t -s $'\t'` (see https://unix.stackexchange.com/questions/7698/command-to-layout-tab-separated-list-nicely)
