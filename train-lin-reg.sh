#!/bin/bash
# Computes the line using linear regression to classify AGs as complex or not complex based on their node count and simplicity.
# This approach is taken from the following paper:
#     Sean Carlisto De Alvarenga, Alessandro Ulrici, Rodrigo Sanches Miani, Michel Cukier, and Bruno Bogaz Zarpel ̃ao.
#     Process mining and hierarchical clustering to help intrusion alert visualization. Computers Security, 73:474–491, 3 2018
#
# Output format: A B vmin vmax
#     where `A + Bx` is the computed regression line, vmin and vmax are the min and max node counts, as defined in the paper.
#
# NB! This script is based on .dot files, which are by default deleted during the execution of SAGE.
#      To prevent the deletion, set the DOCKER variable to False (in SAGE).

set -euo pipefail
IFS=$'\n\t'

umask 077

function usage(){
    echo "Usage: $0 path/to/AGs..."
}

# Check if at least one argument is provided
[[ $# -lt 1 ]] && { usage >&2 ; exit 1; }

# Check if all input directories exist
for dir in $*; do
    ! [[ -d "$dir" ]] && { echo "$0: directory $dir does not exist" >&2 ; exit 1 ; }
done

# `v_min` and `v_max` parameters from the paper. Feel free to change them to whatever you want
vmin=15
vmax=30

# Compute the regression line based on the attack graphs in the provided directories
find $* -type f -name '*.dot' |
    xargs gvpr 'BEG_G { print(nNodes($G)," ", 1.0 * nNodes($G) / nEdges($G)); }' |  # For each attack graph, print its number of nodes and its simplicity ( #nodes / #edges )
    awk '$1 < '"$vmin"' || $1 > '"$vmax"' { print }' |                              # Filter only attack graphs with #nodes < `v_min` or #nodes > `v_max` (definitely not complex or complex, respectively)
    awk '{                                                                          # Compute the regression line using the formula (x is #nodes, y is simplicity, n is the number of attack graphs)
            sx += $1;
            sy += $2;
            ssx += ($1 * $1);
            sxy += ($1 * $2);
            n += 1;
        }
        END {
            denominator = n * ssx - sx * sx;
            A = (sy * ssx - sx * sxy) / denominator;
            B = (n * sxy - sx * sy) / denominator;
            print A " " B " "'"$vmin"' " "'"$vmax"';
        }'

