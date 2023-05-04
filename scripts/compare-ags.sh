#!/bin/bash
# Compares two directories with AGs (presumably, generated by original and modified SAGE algorithm respectively)

# NB! The comparison is based on .dot files, which are by default deleted during the execution of SAGE
#      To prevent deletion, comment out lines 2850-2851 in sage.py
#     In addition, the filenames of the generated AGs have to be the same, so I would recommend running SAGE both times with the same experiment name,
#      and then move the generated AGs from the directory ExpNameAGs/ into e.g. directories ExpName-origAGs/ and ExpName-modifiedAGs/ respectively

set -euo pipefail
IFS=$'\n\t'

umask 077

usage="usage: $0 directory1/ directory2/"

ORIGINAL=$(echo $1/ | tr -s '/')
MODIFIED=$(echo $2/ | tr -s '/')

echo -n "Number of AGs found both by the original and the modified algorithms: "
comm -12 <(find $ORIGINAL -type f -name '*.dot' -printf '%f\n' | sort) <(find $MODIFIED -type f -name '*.dot' -printf '%f\n' | sort) | wc -l # In both (intersection)
echo -ne "\n"

echo -n "Number of AGs found only by the original algorithm: "
comm -23 <(find $ORIGINAL -type f -name '*.dot' -printf '%f\n' | sort) <(find $MODIFIED -type f -name '*.dot' -printf '%f\n' | sort) | wc -l # Only in ORIGINAL
echo "AGs found only by the original algorithm: "
comm -23 <(find $ORIGINAL -type f -name '*.dot' -printf '%f\n' | sort) <(find $MODIFIED -type f -name '*.dot' -printf '%f\n' | sort) # Only in ORIGINAL
echo -ne "\n"

echo -n "Number of AGs found only by the modified algorithm: "
comm -13 <(find $ORIGINAL -type f -name '*.dot' -printf '%f\n' | sort) <(find $MODIFIED -type f -name '*.dot' -printf '%f\n' | sort) | wc -l # Only in MODIFIED
echo "AGs found only by the modified algorithm: "
comm -13 <(find $ORIGINAL -type f -name '*.dot' -printf '%f\n' | sort) <(find $MODIFIED -type f -name '*.dot' -printf '%f\n' | sort) # Only in MODIFIED

