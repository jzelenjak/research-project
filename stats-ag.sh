#!/bin/bash
# Computes statistics for a single attack graph.
# The computed statistics are:
#   - Number of nodes
#   - Number of edges
#   - Simplicity = #nodes / #edges (used to measure complexity)
#   - The number of discovered objective variants (i.e. nodes with hexagon shape and salmon)
# If multiple AGs are provided, then they are processed one after the other.
#
# Output format:    `ag_name \t num_nodes \t num_edges \t simplicity \t num_obj_variants`
# Example:          `10.0.0.100|DATA_EXFILTRATION|microsoft-ds	48	97	0.494845	4`
#
# NB! This script is based on .dot files, which are by default deleted during the execution of SAGE.
#      To prevent the deletion, use the --keep-files option when running SAGE.

set -euo pipefail
IFS=$'\n\t'

umask 077

function usage(){
    echo "Usage: $0 path/to/AG.dot..."
}

# Check if at least one argument is provided
[[ $# -lt 1 ]] && { usage >&2 ; exit 1; }

# Check if all input files exist and if they all have .dot extension
for file in $*; do
    [[ -d "$file" ]] && { echo "$0: $file is a directory" >&2 ; exit 1 ; }
    ! [[ -f "$file" ]] && { echo "$0: file $file does not exist" >&2 ; exit 1 ; }
    ! [[ "${file##*.}" == "dot" ]] && { echo "$0: file $file is not a .dot file" >&2 ; exit 1 ; }
done

# Compute the statistics for each input AG
gvpr '
    BEG_G { int num_obj_variants = 0; }                                             // Initialise the variable for the number of objective variants

    N [ $.shape == "doubleoctagon" ] {                                              // This is the root node, which contains the AG name
        string oneline = gsub(gsub($.name, "\r"), "\n", "|");                       // Put graph name on one line
        string graph_name = gsub(gsub(oneline, "Victim: "), " ", "_");              // Remove the "Victim: " prefix and replace spaces with underscores
    }

    N [ $.shape == "hexagon" && fillcolor == "salmon" ] { num_obj_variants += 1; }  // This is an objective variant 

    END_G {                                                                         // Print the statistics for this AG
        int num_nodes = nNodes($G);
        int num_edges = nEdges($G);
        print(graph_name, "\t", num_nodes, "\t", num_edges, "\t", 1.0 * num_nodes / num_edges, "\t", num_obj_variants);
    }' $*

