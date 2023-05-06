#!/bin/bash
# Computes statistics on two directories with attack graphs to compare them side-by-side
# The computes statistics are:
#   - Number of nodes, edges and simplicity (complexity) for each AG in each directory
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


join -t $'\t' -j 1 \
    <(./stats-nodes-edges.sh "$ORIGINAL" | grep -v -- '-----' | sed 's/Average /Average@/' | sed 's/ count/@count/' | awk '{ print $1 "\t" $2 "\t" $3 }' | tr '@' ' ' | sort) \
    <(./stats-nodes-edges.sh "$MODIFIED" | grep -v -- '-----' | sed 's/Average /Average@/' | sed 's/ count/@count/' | awk '{ print $1 "\t" $2 "\t" $3 }' | tr '@' ' ' | sort) |
    column -t -s $'\t'
