#!/bin/bash
# Computes statistics on a directory with attack graphs.
# The computed statistics are:
#   - Number of nodes, edges, simplicity, whether the AG is complex or not, the number of discovered objective variants (for each AG, see also stats-ag.sh script)
#     Format:  `graph_name \t num_nodes \t num_edges \t simplicity \t is_complex \t num_obj_variants`
#     Example: `10.0.0.1|NETWORK_DoS|ms-wbt-server            70        172  0.406977  Yes  3`
#   - Average number of nodes for all AGs in the directory
#   - Average number of edges for all AGs in the directory
#   - Average simplicity for all AGs in the directory
#
# Note: to train the linear regression model, one or more directories with AGs may be provided.
#     The statistics are in either case computed only for the first provided directory.
# The approach of classifying graphs as complex or not is taken from the following paper:
#     Sean Carlisto De Alvarenga, Alessandro Ulrici, Rodrigo Sanches Miani, Michel Cukier, and Bruno Bogaz Zarpel ̃ao.
#     Process mining and hierarchical clustering to help intrusion alert visualization. Computers Security, 73:474–491, 3 2018
#
# NB! This script is based on .dot files, which are by default deleted during the execution of SAGE.
#      To prevent the deletion, use the --keep-files option when running SAGE.

set -euo pipefail
IFS=$'\n\t'

umask 077

function usage(){
    echo "Usage: $0 path/to/main/AGs [path/to/other/AGs...]"
}

# Check if at least one argument is provided
[[ $# -lt 1 ]] && { usage >&2 ; exit 1; }

# Check if all input directories exist
for dir in $*; do
    ! [[ -d "$dir" ]] && { echo "$0: directory $dir does not exist" >&2 ; exit 1 ; }
done

# The script used to compute the regression line
script_lin_reg="./train-lin-reg.sh"
! [[ -f "$script_lin_reg" ]] && { echo "$0: file $script_lin_reg does not exist" >&2 ; exit 1 ; }

# Compute the regression line
# If you want to use precomputed results to avoid recomputing them on every run,
#   comment out the if-statements, rename the directories (if necessary) and modify `A`, `B`, `vmin` and `vmax` to the precomputed results
# Also, comment out the next line if you don't want to compute the LR line on every run
IFS=" " read A B vmin vmax <<<$($script_lin_reg $*)
# if [[ "$1" =~ "orig-2017AGs" ]] && [[ $# -eq 2 ]] && [[ "$2" =~ "merged-sinks-2017AGs" ]]; then A=1.07333 ; B=-0.0162986 ; vmin=15 ; vmax=30 ;
# elif [[ "$1" =~ "orig-2018AGs" ]] && [[ $# -eq 2 ]] && [[ "$2" =~ "merged-sinks-2018AGs" ]]; then A=1.04091 ; B=-0.019847 ; vmin=15 ; vmax=30 ;
# elif [[ "$1" =~ "orig-2017AGs" ]] && [[ $# -eq 1 ]]; then A=1.07218 ; B=-0.0138029 ; vmin=15 ; vmax=30 ;
# elif [[ "$1" =~ "orig-2018AGs" ]] && [[ $# -eq 1 ]]; then A=1.00286 ; B=-0.0157531 ; vmin=15 ; vmax=30 ;
# else IFS=" " read A B vmin vmax <<<$($script_lin_reg $*);
# fi
# echo "Estimated linear regression parameters: $A $B $vmin $vmax"

# For each AG in the first input directory, run ./stats-ag.sh script and compute the avarage statistics
script="./stats-ag.sh"
find "$1" -type f -name '*.dot' |                                       # Find all the .dot files in the first input directory
    xargs "$script" |                                                   # Run the script on all the found .dot files
    awk -F '\t' '                                                       # Process graphs: classify as complex/non-complex and compute the avarage statistics
        function is_complex(n,s) {                                      # Function to classify graphs as complex/non-complex, as described in the linked paper
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
            print($1 "\t" $2 "\t" $3 "\t" $4 "\t" complex "\t" $5);     # Print the statistics for each processed AG
        }
        END {                                                           # Compute and print the average statistics
            print("Average node count:\t" v / count);
            print("Average edge count:\t" e / count);
            print("Average simplicity:\t" s / count);
        }' |
        column -t -s $'\t'                                              # Make the output aligned (see https://unix.stackexchange.com/questions/7698/command-to-layout-tab-separated-list-nicely)

