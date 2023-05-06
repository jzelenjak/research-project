#!/bin/bash
# Gets the number of nodes, edges and simplicity (complexity) of an AG
# If multiple AGs are provided, then they are processed in turn.
#
# NB! The comparison is based on .dot files, which are by default deleted during the execution of SAGE
#      To prevent deletion, comment out lines 2850-2851 in sage.py
#     In addition, the filenames of the generated AGs have to be the same, so I would recommend running SAGE both times with the same experiment name,
#      and then move the generated AGs from the directory ExpNameAGs/ into e.g. directories ExpName-origAGs/ and ExpName-modifiedAGs/ respectively

set -euo pipefail
IFS=$'\n\t'

umask 077

usage="usage: $0 path/to/AG.dot..."

[[ $# -lt 1 ]] && { echo $usage >&2 ; exit 1; }

for file in $*; do
    [[ -d "$file" ]] && { echo "$0: $file is a directory" >&2 ; exit 1 ; }
    ! [[ -f "$file" ]] && { echo "$0: file $file does not exits" >&2 ; exit 1 ; }
    ! [[ "${file##*.}" == "dot" ]] && { echo "$0: file $file is not a .dot file" >&2 ; exit 1 ; }
done

gvpr 'N {
        if ($.shape == "doubleoctagon") {
            string oneline = gsub($.name, "\n", "|");
            string stripped = gsub(oneline, "Victim: ");
            string nospace = gsub(stripped, " ", "_");
            print(nospace, "\t", nNodes($G), "\t", nEdges($G), "\t", 1.0 * nNodes($G) / nEdges($G));
        } }' $*
