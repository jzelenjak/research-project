#!/bin/bash
# Compares two AGs based on the edges they have (presumably, AGs generated by the original and modified algorithms respectively).
# The computed statistics are (when running in normal mode, i.e. with no options):
#   - Edges found by both algorithms
#   - Edges found only by the original algorithm
#   - Edges found only by the modified algorithm
# If running in quiet mode (i.e. option -q , inspired by the "quick diff"), the script:
#   - Prints that the graphs are different if at least one edge has been found by only one of the algorithms (exit code 1)
#   - Prints nothing if there are no edges found by only one of the algorithms (exit code 0)
#
# Note: The comparison is purely based on the edges of the graphs (their names and labels, to be precise).
#       If two edges with the same name are present in different places in the AGs (e.g at the beginning and end of a path),
#         they are still considered the same.
#       The 'ID' can be removed from the node name (it might be different for original and modified graphs
#         even if the states are the same).
#
# NB! This script is based on .dot files, which are by default deleted during the execution of SAGE.
#      To prevent the deletion, set the DOCKER variable to False (in SAGE).

set -euo pipefail
IFS=$'\n\t'

umask 077

usage() {
    echo -e "Usage: $0 [-i] [-q] originalAG.dot modifiedAG.dot\n\n\t-i\tremove node IDs when comparing the attack graphs\n\t-q\treport only when attack graphs differ (do not print differences)"
}

mode="normal"
keep_ids="true"
if [[ $# -ge 2 ]] && [[ $# -le 4 ]]; then
    num_options=0
    while getopts "qi" option; do
        case ${option} in
            q ) mode="quiet" ; num_options=$((num_options + 1)) ;;
            i ) keep_ids="false" ; num_options=$((num_options + 1)) ;;  # Sort of "insensitive [to IDs]"
            \? ) { usage >&2; exit 1; } ;;
        esac
    done

    pos_original=$((1 + num_options))
    pos_modified=$((2 + num_options))
    original="${@:pos_original:1}"
    modified="${@:pos_modified:1}"
# The number of arguments can only be two, three or four
else
    usage >&2
    exit 1
fi

# Check if all input directories exist and that both files have .dot extension
! [[ -f "$original" ]] && { echo "$0: file $original does not exist" >&2 ; exit 1 ; }
! [[ -f "$modified" ]] && { echo "$0: file $modified does not exist" >&2 ; exit 1 ; }
! [[ "${original##*.}" == "dot" ]] && { echo "$0: file $original is not a .dot file" >&2 ; exit 1 ; }
! [[ "${modified##*.}" == "dot" ]] && { echo "$0: file $modified is not a .dot file" >&2 ; exit 1 ; }

# Put the name of the edge (i.e. "src->dst") next to the label of the edge (time metadata), separated by a "#"
parse_edges(){
    # Format of an edge with an attacker label after executing the `gvpr` script
    # ARBITRARY CODE EXECUTION|ftp | ID: -1->ROOT PRIVILEGE ESCALATION|ms-wbt-server | ID: -1	<font color="magenta"> start_next: 04/11/17, 17:47:40<br/>gap: 4373sec<br/>end_prev: 04/11/17, 16:34:47</font><br/><font color="magenta"><b>Attacker: 10.0.254.31</b></font>
    edges=$(gvpr '
        E [$.label == ""] { print(gsub(gsub($.name, "\r"), "\n", " | ")); }     // For edges without labels, simply print their names
        E [$.label != "" ] {                                                    // For edges with labels, print their names and labels
            string edge_name = gsub(gsub($.name, "\r"), "\n", " | ");           // Get the name of the edge and put it on one line
            string edge_label = gsub(gsub($.label, "\r"), "\n", ", ");          // Get the label of the edge and put it on one line
            print(edge_name + " # " + edge_label);                              // Put the name and the label of the edge next to each other, separated by a "#"
    }' "$1")

    if [[ "$keep_ids" == "false" ]]; then
        edges=$(echo -e "$edges" | sed 's/ | ID: -\?[0-9]\+//g')                # Remove the node ID (if `-i` option is used)
    fi

    echo -e "$edges" |
    sed 's@<br/>@, @g' |                                                        # Replace the <br/> tag with a comma to simplify further parsing
    sed 's/<[^>]*>//g' |                                                        # Remove the HTML tags
    sed 's/->/ -> /g' |                                                         # Add whitespaces around an arrow for readability
    tr -s ' ' |                                                                 # Remove redundant whitespaces (so that there are only single whitespaces)
    sort                                                                        # Sort the edges (`comm` command requires the input to be sorted)
}

# Get the edges generated by the original and modified algorithms
edges_original=$(parse_edges $original)
edges_modified=$(parse_edges $modified)

# Find the edges that are common and edges that are present in only one of the graphs
only_original=$(comm -23 <(echo -e "$edges_original") <(echo -e "$edges_modified"))
only_modified=$(comm -13 <(echo -e "$edges_original") <(echo -e "$edges_modified"))
common=$(comm -12 <(echo -e "$edges_original") <(echo -e "$edges_modified"))

# When running in quiet mode, report if the graphs are different or exit quietly if they are the same
if [[ "$mode" == "quiet" ]]; then
    if [[ -z "$only_original" ]] && [[ -z $only_modified ]]; then
        exit 0;
    else
        echo "Attack graphs $original and $modified are different"
        exit 1
    fi
fi

# When running in normal mode, show the common edges and edges that are present in only one of the graphs (and their counts)
# Common edges (i.e. present in both graphs)
echo "Edges found by both algorithms: $(echo -e "$common" | sed '/^\s*$/d' | wc -l)"
! [[ -z "$common" ]] && echo -e "$common"
echo -ne "\n"

# Edges only present in the original graph
if ! [[ -z "$only_original" ]]; then
    echo "Edges found only by original algorithm: $(echo -e "$only_original" | wc -l)"
    echo -e "$only_original"
else
    echo "Edges found only by original algorithm: 0"
fi

# Edges only present in the modified graph
if ! [[ -z "$only_modified" ]]; then
    echo -ne "\n"
    echo "Edges found only by modified algorithm: $(echo -e "$only_modified" | wc -l)"
    echo -e "$only_modified"
else
    echo "Edges found only by modified algorithm: 0"
fi

