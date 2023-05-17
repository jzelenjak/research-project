#!/bin/bash
# Computes the statistics on nodes for a directory with AGs
# The computed statistics are:
#   - Total number of nodes across all the AGs in the provided directory
#   - Number of unique nodes across all the AGs in the provided directory
#   - Total number of sink nodes across all the AGs in the provided directory (and their percentage)
#   - Number of unique sink nodes across all the AGs in the provided directory (and their percentage)
#
# NB! The comparison is based on .dot files, which are by default deleted during the execution of SAGE
#      To prevent deletion, set the variable DOCKER to False

set -euo pipefail
IFS=$'\n\t'

umask 077

usage="usage: $0 AGs/"

[[ $# -ne 1 ]] && { echo $usage >&2 ; exit 1; }

DIR=$(echo "$1/" | tr -s '/')
! [[ -d "$DIR" ]] && { echo "$0: directory $DIR does not exits" >&2 ; exit 1 ; }

nodes_total=$(find "$DIR" -type f -name '*.dot' | xargs gvpr 'N { print(gsub(gsub($.name, "\r"), "\n", " | ")); }' | wc -l)
nodes_unique=$(find "$DIR" -type f -name '*.dot' | xargs gvpr 'N { print(gsub(gsub($.name, "\r"), "\n", " | ")); }' | sort | uniq -i | wc -l)  # root counts as a unique node even if it appears somewhere in another graph
sinks_total=$(find "$DIR" -type f -name '*.dot' | xargs gvpr 'N [ $.style == "dotted" || $.style == "filled,dotted" || $.style == "dotted,filled" ] { print(gsub(gsub($.name, "\r"), "\n", " | ")); }' | wc -l)
sinks_unique=$(find "$DIR" -type f -name '*.dot' | xargs gvpr 'N [ $.style == "dotted" || $.style == "filled,dotted" || $.style == "dotted,filled" ] { print(gsub(gsub($.name, "\r"), "\n", " | ")); }' | sort | uniq -i | wc -l)

echo "Total number of nodes: $nodes_total"
echo "Number of unique nodes: $nodes_unique"
echo "Total number of sink nodes: $sinks_total ($(echo "scale=3; 100 * $sinks_total / $nodes_total" | bc)%)"
echo "Number of unique sink nodes: $sinks_unique ($(echo "scale=3; 100 * $sinks_unique / $nodes_unique" | bc)%)"

# Comment out to print all the shapes that sinks nodes have
# echo -ne "Shapes of sink-nodes: " ; find "$DIR" -type f -name '*.dot' | xargs grep -F -l "dotted" | xargs gvpr 'N [ $.style == "dotted" || $.style == "filled,dotted" || $.style == "dotted,filled" ] { print($.shape); }' | sort -u | paste -sd ','

# Comment out to print all unique nodes
# find "$DIR" -type f -name '*.dot' | xargs gvpr 'N { print(gsub(gsub($.name, "\r"), "\n", " | ")); }' | sort | uniq -i

# Comment out to print all unique sink nodes
# find "$DIR" -type f -name '*.dot' | xargs grep -F -l "dotted" | xargs gvpr 'N [ $.style == "dotted" || $.style == "filled,dotted" || $.style == "dotted,filled" ] { print(gsub(gsub($.name, "\r"), "\n", " | ")); }' | sort | uniq -i
