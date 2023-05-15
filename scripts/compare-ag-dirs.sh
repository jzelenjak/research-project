#!/bin/bash
# Compares two directories with AGs (presumably, generated by original and modified SAGE algorithm respectively)
#
# NB! The comparison is based on .dot files, which are by default deleted during the execution of SAGE
#      To prevent deletion, comment out lines 2850-2851 in sage.py, or set DOCKER to False

set -euo pipefail
IFS=$'\n\t'

umask 077

usage="usage: $0 directory1/ directory2/"

[[ $# -ne 2 ]] && { echo $usage >&2 ; exit 1; }

ORIGINAL=$(echo $1/ | tr -s '/')
MODIFIED=$(echo $2/ | tr -s '/')

! [[ -d "$ORIGINAL" ]] && { echo "$0: directory $ORIGINAL does not exits" >&2 ; exit 1 ; }
! [[ -d "$MODIFIED" ]] && { echo "$0: directory $MODIFIED does not exits" >&2 ; exit 1 ; }

echo -n "Number of AGs found both by the original and the modified algorithms: "
comm -12 <(find "$ORIGINAL" -type f -name '*.dot' -printf '%f\n' | sed 's/^.*attack-graph-for-victim-\(.*\)$/\1/'| sed 's/Unknown/unknown/' | sort) <(find "$MODIFIED" -type f -name '*.dot' -printf '%f\n' | sed 's/^.*attack-graph-for-victim-\(.*\)$/\1/' | sed 's/Unknown/unknown/' | sort) | wc -l
echo -ne "\n"

echo -n "Number of AGs found only by the original algorithm: "
comm -23 <(find "$ORIGINAL" -type f -name '*.dot' -printf '%f\n' | sed 's/^.*attack-graph-for-victim-\(.*\)$/\1/'| sed 's/Unknown/unknown/' | sort) <(find "$MODIFIED" -type f -name '*.dot' -printf '%f\n' | sed 's/^.*attack-graph-for-victim-\(.*\)$/\1/' | sed 's/Unknown/unknown/' | sort) | wc -l
echo "AGs found only by the original algorithm: "
comm -23 <(find "$ORIGINAL" -type f -name '*.dot' -printf '%f\n' | sed 's/^.*attack-graph-for-victim-\(.*\)$/\1/'| sed 's/Unknown/unknown/' | sort) <(find "$MODIFIED" -type f -name '*.dot' -printf '%f\n' | sed 's/^.*attack-graph-for-victim-\(.*\)$/\1/' | sed 's/Unknown/unknown/' | sort)
echo -ne "\n"

echo -n "Number of AGs found only by the modified algorithm: "
comm -13 <(find "$ORIGINAL" -type f -name '*.dot' -printf '%f\n' | sed 's/^.*attack-graph-for-victim-\(.*\)$/\1/'| sed 's/Unknown/unknown/' | sort) <(find "$MODIFIED" -type f -name '*.dot' -printf '%f\n' | sed 's/^.*attack-graph-for-victim-\(.*\)$/\1/' | sed 's/Unknown/unknown/' | sort) | wc -l
echo "AGs found only by the modified algorithm: "
comm -13 <(find "$ORIGINAL" -type f -name '*.dot' -printf '%f\n' | sed 's/^.*attack-graph-for-victim-\(.*\)$/\1/'| sed 's/Unknown/unknown/' | sort) <(find "$MODIFIED" -type f -name '*.dot' -printf '%f\n' | sed 's/^.*attack-graph-for-victim-\(.*\)$/\1/' | sed 's/Unknown/unknown/' | sort)

