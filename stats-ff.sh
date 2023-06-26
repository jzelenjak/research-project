#!/bin/bash
# Computes the number of red, blue and white nodes, and the number of sink nodes generated by FlexFringe.
# First it resolves the experiment name (ExpName) to the corresponding FlexFringe .json files and then computes the statistics.
#
# NB! It is assumed that FlexFringe has been run with parameters `outputsinks=1` and `printblue=1`.
#
# Note: this script is based on the .json files that SAGE receives from FlexFringe.
#   Full S-PDFA can be analysed by setting `printblue=1`, `printwhite=1` and `printred=1` (default)
#     and querying the file `ExpName.txt.ff.final.json`.
#
# Note: as I have noticed, merging sinks after the main merging process might result in some sinks becoming red (core) states
#     that will remain sinks even if their count is larger than or equal to the `sinkcount` parameter 
#     (due to extending a blue sink, i.e. colouring red, if it is the best refinement).
#   Hence the statistics should be interpreted as follows:
#     - Before merging sinks: #sinks = #blue + #white
#     - After merging sinks: #sinks = #red_sinks
#
# NB! This script is based on .json files, which are by default deleted during the execution of SAGE.
#      To prevent the deletion, set the DOCKER variable to False (in SAGE).

set -euo pipefail
IFS=$'\n\t'

umask 077

function usage(){
    echo "Usage: $0 ExpName"
}

# Check if exactly one argument is provided
[[ $# -ne 1 ]] && { usage >&2 ; exit 1; }

# Resolve the FlexFringe files based on the experiment name
core_json="${1}.txt.ff.final.json"
sinks_json="${1}.txt.ff.finalsinks.json"

# Check if these FlexFringe files exist
! [[ -f "$core_json" ]] && { echo "$0: file $core_json does not exits" >&2 ; exit 1 ; }
! [[ -f "$sinks_json" ]] && { echo "$0: file $sinks_json does not exits" >&2 ; exit 1 ; }

# Compute the statistics on the states of the resulting S-PDFA learned by FlexFringe
red=$(jq '.nodes[] | select(.isred==1) | .id' "$core_json" "$sinks_json" | sort -u | wc -l)
blue=$(jq '.nodes[] | select(.isblue==1) | .id' "$core_json" "$sinks_json" | sort -u | wc -l)
white=$(jq '.nodes[] | select(.isred==0 and .isblue==0) | .id' "$core_json" "$sinks_json" | sort -u | wc -l)
sinks=$(jq '.nodes[] | select(.issink==1) | .id' "$core_json" "$sinks_json" | sort -u | wc -l)
total=$((red + blue + white))

# Print the resulting state counts as well as their percentage of the total (for red, blue and white nodes)
echo "Total red states (core): $red ($(echo "scale=3; 100 * $red / $total" | bc)%)"
echo "Total blue states: $blue ($(echo "scale=3; 100 * $blue / $total" | bc)%)"
echo "Total white states: $white ($(echo "scale=3; 100 * $white / $total" | bc)%)"
echo "Total sink states: $sinks ($(echo "scale=3; 100 * $sinks / $total" | bc)%)"
echo "Total states (red + blue + white): $total"

