#!/bin/bash
# Tests whether sink states in the attack graphs are consistent with the sink states 
#
# The idea is to verify that all dotted states in the AGs are indeed sinks in FlexFringe output files.
#   - First, we get all unique sinks in CPTC-2017 (analogously for CPTC-2018) from the AGs.
#   - Then, using `jq`, we take all sink states from `orig-2017.txt.ff.finalsinks.json` file generated by FlexFringe (the name might be different), and extract their IDs.
#   - Finally, we take the intersection between the sink IDs found in the AGs and the sink IDs found in the FlexFringe output file (`comm -12 ...`) and count them (`... | wc -l`).
#   - The result the result must be equal to the number of unique sink IDs found in the AGs, which would mean that all states defined as sinks in the AGs are also sinks in the FlexFringe file with the sinks.
#
# Similarly, we can verify that all non-sinks with IDs are indeed non-sinks (using `orig-2017.txt.ff.final.json` file, potentially with a different name).
#
# Note: when comparing non-sinks, we select non-sinks or red sinks. The reason is that when merging sinks, some of them might be coloured red but still remain sinks (i.e. during extension; `issink` will be 1).
#   Since they are still in the core model (as sinks model, essentially, does not exist anymore), SAGE considers them as non-sinks, which makes sense, as they are part of the red core.


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

# Resolve the directory with the attack graphs
dir_ags="${1}AGs/"

# Check if this directory exists
! [[ -d "$dir_ags" ]] && { echo "$0: directory $dir_ags does not exist" >&2 ; exit 1 ; }


echo "Checking sinks (all sinks in the AGs must also be sinks in the S-PDFA)..."
# All found sinks in 2017 are indeed sinks
sinks_ags=$(find "$dir_ags" -type f -name '*.dot' | xargs gvpr 'N [ index($.style, "dotted") != -1 ] { print(gsub(gsub($.name, "\r"), "\n", " | ")); }' | sort -u)
sinks_ff=$(jq '.nodes[] | select(.issink==1) | .id' "$sinks_json" | sort)
num_sinks_ags=$(echo -e "$sinks_ags" | sed '/^$/d' | wc -l)
num_common_sinks_ff=$(comm -12 <(echo -e "$sinks_ags" | sed '/^$/d' | sed 's/^.*ID: \([0-9-]\+\)$/\1/' | sort) <(echo -e "$sinks_ff" | sed '/^$/d') | wc -l)
# If `num_sinks_ags` > `num_common_sinks_ff`, then some sinks in AGs are non sinks in FlexFringe (should not happen)
echo "Sinks in the attack graphs: $num_sinks_ags"
echo "Sinks in the S-PDFA (intersection): $num_common_sinks_ff"
[[ "$num_sinks_ags" -ne "$num_common_sinks_ff" ]] && exit 1


echo "Checking non-sinks (all non-sinks with IDs in the AGs must also be sinks in the S-PDFA)..."
# All non-sinks with IDs in 2017 are indeed non-sinks
non_sinks_with_ids_ags=$(find "$dir_ags" -type f -name '*.dot' | xargs gvpr 'N [ index($.style, "dotted") == -1 ] { print(gsub(gsub($.name, "\r"), "\n", " | ")); }' | sort -u | grep 'ID: ')
non_sinks_ff=$(jq '.nodes[] | select(.issink==0 or .isred == 1) | .id' "$core_json" | sort)
num_non_sinks_ags=$(echo -e "$non_sinks_with_ids_ags" | sed '/^$/d' | wc -l)
num_common_non_sinks_ff=$(comm -12 <(echo -e "$non_sinks_with_ids_ags" | sed '/^$/d' | sed 's/^.*ID: \([0-9-]\+\)$/\1/' | sort -u) <(echo -e "$non_sinks_ff" | sed '/^$/d') | wc -l)
# If `num_non_sinks_ags` > `num_common_non_sinks_ff`, then some non-sinks in AGs are sinks in FlexFringe
echo "Non-sinks in the attack graphs: $num_non_sinks_ags"
echo "Non-sinks in the S-PDFA (intersection): $num_common_non_sinks_ff"

[[ "$num_non_sinks_ags" -ne "$num_common_non_sinks_ff" ]] && exit 1
exit 0
