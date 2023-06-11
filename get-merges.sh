#!/bin/bash
# Gets the nodes affected by a merge during the FlexFringe PDFA learning process for each merge iteration and combines the results into a single PDF file.
#
# This script analyses testXXXX.dot files generated by FlexFringe, which are printed before every merge (set `debug = 1`, also `printwhite = 1` and `printblue = 1`).
#
# The script filters out only the states that have been affected by a merge, i.e. the states that have changed their:
#   - representatives
#   - count (frequency), or
#   - degree (number of incoming and outgoing edges)
# It skips the merges where nothing happened (i.e. blue nodes have been coloured to red and their white children to blue),
#     since they are not interested and are large.
# For each merge, it combines the affected "before" and "after" fragments of the PDFA into one image
#     and finally combines all of them into one PDF file.
# To facilitate the analysis, the red and blue nodes that have been merged at the beginning of an iteration are coloured much darker and have white font colour.
#     Furthermore, blue nodes that have changed their representatives and red nodes that have changed their counts (they do not change their representative)
#       are coloured slightly darker.
#     Finally, for every affected node, its incoming edges, together with their endpoints, are displayed to create some context.

set -euo pipefail
IFS=$'\n\t'

umask 077

usage() {
    echo -e "Usage: $0 [output.pdf]"  # By default, `merges.pdf` file will be used for output
}

# Store the output file name if specified
out="merges.pdf"
[[ $# -eq 1 ]] && out="$1"

# Check if the dependencies are present
img2pdf --help > /dev/null
convert --help > /dev/null

# Iterate over each consecutive pair of testXXXX.dot files to get a "smart" diff
sink_count=5
num_tests=$(find . -type f -name '*test*.dot' | wc -l)
for t in $(seq 1 $((num_tests - 1))); do
    # Create variables tor test files and test numbers
    t1=$(printf "%04d" $t)
    t2=$(printf "%04d" $((t + 1)))
    test1="test${t1}.dot"
    test2="test${t2}.dot"

    # Check if the test files exist
    [[ -f "$test1" ]] || { echo "$0: file $test1 does not exist" >&2 ; exit 1 ; }
    [[ -f "$test2" ]] || { echo "$0: file $test2 does not exist" >&2 ; exit 1 ; }

    # Create variables for temporary files
    merge_before="merge${t1}-before"
    merge_before_dot="merge${t1}-before.dot"
    merge_before_png="merge${t1}-before.png"
    merge_after="merge${t1}-after"
    merge_after_dot="merge${t1}-after.dot"
    merge_after_png="merge${t1}-after.png"
    merge_png="merge${t1}.png"

    # Get a "smart" diff for the current merge iteration
    echo -e "Merge $t\n---------"
    gvpr 'BEGIN {
            // Create "before" and "after" graphs
            graph_t before = graph("'"$merge_before"'", "D");
            graph_t after = graph("'"$merge_after"'", "D");

            // Make the rendering more consistent
            before.ordering = "out";
            after.ordering = "out";

            // Get the representative of a node given its label
            string get_representative(node_t n) {
                if (n.name == "I") return "I";                          // Skip the artificial "I" node as it has no label
                string label = gsub(gsub(n.label, "\r"), "\n", "|");    // Put the label on one line
                int start_cut = index(label, "rep#") + 4;               // Find the starting index of the cut
                int end_cut = rindex(label, "|");                       // Find the ending index of the cut
                return substr(label, start_cut, end_cut - start_cut);   // Return the representative
            }

            // Get the name of a node (i.e. its number) given its label
            string get_name(node_t n) {
                if (n.name == "I") return "I";                          // Skip the artificial "I" node as it has no label
                return substr(n.label, 0, index(n.label, ":#"));        // Return the name
            }

            // Get the count of a node given its label
            int get_count(node_t n) {
                if (n.name == "I") return "I";                          // Skip the artificial "I" node as it has no label
                return substr(n.label, rindex(n.label, "#") + 1);       // Return the count
            }
         }

         N [ $NG != NULL ] {                                            // First iteration, when the graph "before" is the current graph and the graph "after" is the next graph
            node_t node2 = isNode($NG, $.name);                         // Corresponding node in the graph "after"

            //if (node2 != NULL && ($.fillcolor != node2.fillcolor || $.label != node2.label || $.degree != node2.degree)) {  // Print also if no merges have occurred (NB! I have not tested it with the final script version)
            if (node2 != NULL && ($.label != node2.label || $.degree != node2.degree)) {  // Consider a node only if an actual merge has occurred
                // Clone the current and the corresponding nodes to the "before" and "after" graphs respectively
                clone(before, $); 
                clone(after, node2); 
                //print(get_name($) + ": " + (string)get_count($) + " -> " + get_name(node2) + ": " + (string)get_count(node2));

                // Colour the red and blue nodes that have changed their counts and representatives respectively a bit darker
                if ($.label != node2.label) {
                    if (node2.fillcolor == "firebrick1") node2.fillcolor = "firebrick3";
                    if (node2.fillcolor == "dodgerblue1" && get_representative(node2) != get_representative($)) node2.fillcolor = "dodgerblue3";
                }

                // Add all incoming edges of the current node with their endpoints to the graph "before" to create a context (tail -> head)
                edge_t edge1 = fstedge_sg($G, $);
                while (edge1 != NULL) {
                    if ($.name == edge1.head.name) clone(before, edge1);
                    edge1 = nxtedge_sg($G, edge1, $);
                }

                // Add all incoming edges of the corresponding node with their endpoints to the graph "after" to create a context (tail -> head)
                edge_t edge2 = fstedge_sg($NG, node2);
                while (edge2 != NULL) {
                    if (node2.name == edge2.head.name) clone(after, edge2);
                    edge2 = nxtedge_sg($NG, edge2, node2);
                }
            }
        }

        END {
            // Skip empty graphs (for which no merges have actually occurred)
            if (nNodes(before) > 0 && nNodes(after) > 0) {
                // From the affected nodes, find red and blue nodes that have actually been merged (initially) and colour them darker
                node_t blue_node = fstnode(after);
                while (blue_node != NULL) {
                    // Only consider the affected blue nodes that have changed their representatives
                    if (blue_node.fillcolor == "dodgerblue3") {
                        node_t red_node = fstnode(after);
                        int found = 0;
                        while (red_node != NULL) {
                            // Only consider the affected red nodes (i.e. that have changed their colours) and get the one that has been merged
                            if (red_node.fillcolor == "firebrick3" && get_representative(blue_node) == get_name(red_node)) {  
                                print("Highlighting merged red and blue nodes...");

                                blue_node.fillcolor = "dodgerblue4"; blue_node.fontcolor = "white";
                                red_node.fillcolor = "firebrick4"; red_node.fontcolor = "white";

                                node_t blue_node_orig = isNode(before, blue_node.name); blue_node_orig.fillcolor = "dodgerblue4"; blue_node_orig.fontcolor = "white";
                                node_t red_node_orig = isNode(before, red_node.name); red_node_orig.fillcolor = "firebrick4"; red_node_orig.fontcolor = "white";

                                // If a red sink has been merged, report it and colour this sink node to magenta
                                if (get_count(red_node_orig) < '"$sink_count"') {
                                    print("RED SINK STATE HAS BEEN MERGED (MERGE '"$t"'): #" + (string)get_count(red_node_orig) + " -> #" + (string)get_count(red_node));
                                    red_node.fillcolor = "magenta";
                                    red_node_orig.fillcolor = "magenta";
                                }

                                found = 1;
                                break;
                            }
                            red_node = nxtnode_sg(after, red_node);
                        }
                        // Break the loop if the merged red and blue states have already been found
                        if (found == 1) break;
                    }
                    blue_node = nxtnode_sg(after, blue_node);
                }

                // Write the graphs to the temporary DOT files
                writeG(before, "'"$merge_before_dot"'"); 
                writeG(after, "'"$merge_after_dot"'");
            } else {
                // Report that no merges have occurred in this iteration
                print("No merges have occurred -- skipping");
            }
        }' "$test1" "$test2"

    # If a merge has occurred, render the generated graphs
    if [[ -f "$merge_before_dot" ]]; then
        # Render the graphs into separate PNG images
        dot -Tpng -Glabel="Merge ${t}: Before" "$merge_before_dot" -o "$merge_before_png" 
        dot -Tpng -Glabel="Merge ${t}: After" "$merge_after_dot" -o "$merge_after_png"

        # (Horizontally) Combine the graphs to one PNG image
        convert -append "$merge_before_png" "$merge_after_png" "$merge_png"

        # Remove the separate PNG and DOT files of the graphs (they are not needed anymore)
        rm "$merge_before_dot" "$merge_after_dot" "$merge_before_png" "$merge_after_png" 
    fi
done

echo "--------------------"

# Combine all merges into one PDF file (A1 format)
echo "Combining all merges into one PDF file..."

find . -maxdepth 1 -type f -name '*merge*.png' | sort | xargs -r img2pdf --pagesize A1^T -o "$out" 2> /dev/null

# Remove the separate PNG files with merges
rm merge*.png
