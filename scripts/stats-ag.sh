#!/bin/bash
# Gets the number of nodes, edges and simplicity (complexity) and the number of discovered objective variants of an AG
# If multiple AGs are provided, then they are processed in turn.
#
# Output format: (graph_name, num_nodes, num_edges, simplicity, num_obj_variants)
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

gvpr '
    BEG_G {
        graph_t obj_variants = graph("Objective_variants", "D");
        string graph_name = "";
        int num_nodes = 0;
        int num_edges = 0;
        int num_obj_variants = 0;
    }

    N [ $.shape == "doubleoctagon" ] {
        string proper_name = gsub($.name, "\r");
        string oneline = gsub(proper_name, "\n", "|");
        string stripped = gsub(oneline, "Victim: ");
        graph_name = gsub(stripped, " ", "_");
        num_nodes = nNodes($G);
        num_edges = nEdges($G);
    }

    N [ $.shape == "hexagon" && fillcolor == "salmon" ] {
        num_obj_variants += 1;
    }

    END_G {
        print(graph_name, "\t", num_nodes, "\t", num_edges, "\t", 1.0 * num_nodes / num_edges, "\t", num_obj_variants);
    }' $*
