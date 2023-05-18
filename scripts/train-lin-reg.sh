#!/bin/bash
# Computes the line using linear regression to classify AGs as complex or not complex based on simplicity
# This approach is taken from the following paper:
#     Sean Carlisto De Alvarenga, Alessandro Ulrici, Rodrigo Sanches Miani, Michel Cukier, and Bruno Bogaz Zarpel ̃ao.
#     Process mining and hierarchical clustering to help intrusion alert visualization. Computers Security, 73:474–491, 3 2018
#
# NB! The comparison is based on .dot files, which are by default deleted during the execution of SAGE
#      To prevent deletion, comment out lines 2850-2851 in sage.py, or set DOCKER to False

set -euo pipefail
IFS=$'\n\t'

umask 077

usage="usage: $0 path/to/original/AGs..."

[[ $# -lt 1 ]] && { echo $usage >&2 ; exit 1; }

for dir in $*; do
    ! [[ -d "$dir" ]] && { echo "$0: directory $dir does not exist" >&2 ; exit 1 ; }
done

vmin=15
vmax=30
find $* -type f -name '*.dot' |
    xargs gvpr 'BEG_G { print(nNodes($G)," ", 1.0 * nNodes($G) / nEdges($G)); }' |
    awk '$1 < '"$vmin"' || $1 > '"$vmax"' { print }' |
    awk '{
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

