#!/bin/bash
# Executes a bunch of regression tests attack graphs. These test scripts include:
#   - stats-ff.sh
#   - compare-ag-dirs.sh
#   - diff-ags.sh
#     - diff-nodes.sh
#     - diff-edges.sh
#   - stats-nodes-ags.sh
#   - stats-sinks.sh

set -euo pipefail
IFS=$'\n\t'

umask 077


function usage(){
    echo "Usage: $0 ExpName1 ExpName2"
}

# Check if exactly two arguments are provided
[[ $# -ne 2 ]] && { usage >&2 ; exit 1; }

# Experiment names that have been used to run SAGE
orig_exp_name="$1"
updated_exp_name="$2"

# Resolve the FlexFringe files based on the experiment name
orig_traces="${1}.txt"
updated_traces="${2}.txt"

# Check if these FlexFringe files exist
! [[ -f "$orig_traces" ]] && { echo "$0: file $orig_traces does not exits" >&2 ; exit 1 ; }
! [[ -f "$updated_traces" ]] && { echo "$0: file $updated_traces does not exits" >&2 ; exit 1 ; }

# Resolve the directories with the attack graphs
orig_ags="${1}AGs/"
updated_ags="${2}AGs/"

# Check if this directory exists
! [[ -d "$orig_ags" ]] && { echo "$0: directory $orig_ags does not exist" >&2 ; exit 1 ; }
! [[ -d "$updated_ags" ]] && { echo "$0: directory $updated_ags does not exist" >&2 ; exit 1 ; }

trap 'echo Failed' ERR


echo "Test 1: Performing diffs on traces"
diff -q "$orig_traces" "$updated_traces"
echo "Passed"
echo "------------"


echo "Test 2: Performing diffs on FlexFringe stats"
diff <(./stats-ff.sh "$orig_exp_name") <(./stats-ff.sh "$updated_exp_name")
echo "Passed"
echo "------------"


echo "Test 3: Comparing directories"
./compare-ag-dirs.sh "$orig_ags" "$updated_ags"
echo "Passed"
echo "------------"


echo "Test 4: Performing diffs on AGs"
./diff-ags.sh "$orig_ags" "$updated_ags"
echo "Passed"
echo "------------"


echo "Test 5: Checking node stats"
diff -q <(./stats-nodes-ags.sh "$orig_ags") <(./stats-nodes-ags.sh "$updated_ags")
echo "Passed"
echo "------------"


echo "Test 6: Checking sinks stats"
./stats-sinks-ags.sh -t "$orig_ags" "$updated_ags"
echo "Passed"
echo "------------"


echo "Done"
exit 0