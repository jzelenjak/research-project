# Scripts for CSE3000 Research Project course

## Description

This repository contains the scripts that I have used for the research project course at TU Delft (CSE3000). My research was about [SAGE](https://github.com/tudelft-cda-lab/SAGE) (IntruSion alert-driven Attack Graph Extractor) - a tool that generates alert-driven attack graphs based on intrusion alerts (for more information about SAGE, see [SAGE: Intrusion Alert-driven Attack Graph Extractor](https://ieeexplore.ieee.org/abstract/document/9629418), [Alert-driven Attack Graph Generation using S-PDFA](https://ieeexplore.ieee.org/abstract/document/9557854) and [Enabling Visual Analytics via Alert-driven Attack Graphs](https://dl.acm.org/doi/abs/10.1145/3460120.3485361)).

**Title**: *Investigating the Impact of Merging Sink States on Alert-Driven Attack Graphs*

**Subtitle**: *The effects of merging sink states with other sink states and the core of the S-PDFA*

In the section [Scripts](#scripts) below, you can find the description of each script, its usage (which is also explained in the script) and an example use case. This should help you find out which script you might want to use if you want to do a particular task. More extensive documentation can be found in the scripts themselves.

Note: all scripts are written in Bash. While explaining every single Unix command is outside the scope of this research, I have added extensive comments into each script. This way, even those who have no experience with Unix tools can follow the steps of the scripts.

In the directory [results](results/) you can find some of the results for CPTC-2017 and CPTC-2018 datasets. These include:

- General statistics of attack graph comparisons
- A PDF file with merges and a log file generated by the script `get-merges.sh`, as well as FlexFringe logs (self-made) for three versions of SAGE: *original* (`mergesinks=0` and `mergesinkscore=0`), *merged sinks* (`mergesinks=1` and `mergesinkscore=1`) and *looping sinks* (`mergesinks=1` and `mergesinkscore=0`)

## Dependencies

- [SAGE](https://github.com/tudelft-cda-lab/SAGE) (as well as its dependencies)
- [FlexFringe](https://github.com/tudelft-cda-lab/FlexFringe) (to run SAGE)
- Unix packages:
    - `img2pdf`
    - `imagemagick`

## Scripts

Below you can find the description, usage and an example use case for each script. For more information, see the script of interest.

### ag-utils.sh

**Description**: this is not really a script, but rather a file that contains some helpful functions, primarily for resolving attack graph names to .dot files or .png files.

**Usage**: `agf 'victim|mcat|mServ'`, `agfc 'victim|mcat|mServ' 'filter_str'`, `ag 'victim|mcat|mServ'`, `ag-comb 'victim|mcat|mServ'`, `ag-diff 'victim|mcat|mServ'` 

**Example use case**: after running `stats-ags-comp.sh` script, you want to quickly see how exactly the attack graphs are different. You copy the name of the attack graph and the script will resolve it to .dot file(s) (which you can later use) or open a png image(s) of the attack graphs.

### combine-ags.sh

**Description**: this script is used to generate .png images with the corresponding attack graphs placed side by side to facilitate comparison.

**Usage**: `./combine-ags.sh path/to/AGs path/to/AGs`

**Example use case**: after running SAGE on CPTC-2017 (or CPTC-2018) before and after merging sinks states, you can run this script on the directories with the generated attack graphs to generate "side-by-side" .png images.

### compare-ag-dirs.sh

**Description**: this script compares two directories with attack graphs and shows the similarities and differences in terms of the generated attack graphs. Note: this script is only based on the file names. The generated attack graphs might be the same but they can also be different. Use `diff-ags.sh` to compare the contents of attack graphs.

**Usage**: `./compare-ag-dirs.sh path/to/AGs path/to/AGs`

**Example use case**: after running SAGE on CPTC-2017 (or CPTC-2018) before and after merging sinks states, you can run this script on the directories with the generated attack graphs to see how many attack graphs have been generated by each version of SAGE, how many attack graphs are common and how many attack graphs (and which ones) have been generated by only one version of SAGE.

### diff-ags.sh

**Description**: this script compares the attack graphs in terms of the present nodes and edges. Note: it is based on the names and labels of nodes and edges and not on their position in the graph.

**Usage**: `./diff-ags.sh [-q] originalAG.dot modifiedAG.dot` or `./diff-ags.sh originalAGs/ modifiedAGs/` (`-q` - report only when attack graphs differ (do not print differences; can only be used with the .dot files))

**Example use case**: after running SAGE on CPTC-2017 (or CPTC-2018) before and after merging sinks states, you want to see which attack graphs (or how many of them) are different. You can compare two attack graphs (less frequent use case; usually `diff-nodes.sh` is used more often in this case), as well as two directories with attack graphs (more common use case).

### diff-edges.sh

**Description**: this script compares the attack graphs in terms of the present edges. Note: it is based on the names and labels of edges and not on their position in the graph. This script is primarily used as part of `diff-ags.sh` script, however it can still be used on its own.

**Usage**: `./diff-edges.sh [-q] originalAG.dot modifiedAG.dot` (`-q` - report only when attack graphs differ (do not print differences))

**Example use case**: after running `stats-ags-comp.sh` script, you want to see what are the differences in edges for a pair of attack graphs (what are the common edges and which edges are present in only one of the graphs). Here you can use `agf` function from `ag-utils` file to quickly get the .dot files for this script.

### diff-nodes.sh

**Description**: this script compares the attack graphs in terms of the present nodes. Note: it is based on the names of nodes and not on their position in the graph.

**Usage**: `./diff-nodes.sh [-q] originalAG.dot modifiedAG.dot` (`-q` - report only when attack graphs differ (do not print differences))

**Example use case**: after running `stats-ags-comp.sh` script, you want to see what are the differences in nodes for a pair of attack graphs (what are the common nodes and which nodes are present in only one of the graphs). Here you can use `agf` function from `ag-utils` file to quickly get the .dot files for this script.

### get-ids.sh

**Description**: this script gets all node IDs for a specific node (e.g. `mcat|mserv`) from a directory with attack graphs. This script is especially useful in combination with the script `get-merges.sh` to find the interesting merges. Nevertheless, it can still be used on its own to see which (sink) nodes were present before merging sinks and which are present after merging sinks.

**Usage**: `./get-ids.sh path/to/AGs 'mcat'`

**Example use case**: you want to see which (or how many) nodes there are for a specific `mcat|mserv`. For example, you might want to check which nodes there are for `ACCOUNT MANIPULATION|snmp` in the attack graphs of CPTC-2017 dataset. Then you might "grep" a node ID in the `merges.log` generated by `get-merges.sh` script to find the respective merges.

### get-merges.sh

**Description**: this script is used to analyse the merges performed by FlexFringe during the S-PDFA learning process. It takes a "smart" diff between two consecutive states of the S-PDFA to show the affected states before and after a merge (placed vertically next to each other). The result is a (large) PDF file with all non-trivial merges. In addition, this script creates a log file with the main information about the merges to facilitate the analysis (e.g. which red and blue states have been merged and on which edge, which nodes have been merged during the determinization process and on which edge, and which merges have been skipped). Finally, some visual enhancements are added to further facilitate the analysis (see the script for further documentation). 

**Usage**: `./get-merges.sh [output.pdf]`

**Example use case**: you want to analyse how states are merged in the S-PDFA to get insights into what is happening in the S-PDFA learning process (mostly used when running SAGE with merging sinks). You can process the log file to find interesting merges and analyse them further in the PDF file (e.g. you do `grep 'acctManip|snmp' merges.log` and then open the page(s) mentioned in the log).

### get-paths.sh

**Description**: this script gets the attack paths from the attack graphs generated by SAGE. You can use this script on one attack graph (less common use case) or on a directory with the attack graphs (more common use case).

**Usage**: `./get-paths.sh (ag.dot | AGs/)`

**Example use case**: you want to find the attack paths present in the AGs generated by SAGE.

### stats-ag.sh

**Description**: this script computes statistics on a single attack graph generated by SAGE (although, multiple AGs can be provided, in which case they will be processed on after each other). This script is primarily used as part of `stats-ags.sh` script, but can also be used on its own.

The computed statistics are:

- *Number of nodes*
- *Number of edges*
- *Simplicity* (number of nodes / number of edges, used to measure complexity)
- *Number of discovered objective variants* (i.e. nodes with hexagon shape and salmon colour).

**Usage**: `./stats-ag.sh path/to/AG.dot...`

**Example use case**: you want to compute statistics (mentioned above) for one attack graph (or a pair of attack graphs). Here you can use `agf` function from `ag-utils` file to quickly get the .dot files for this script.

### stats-ags-comp.sh

**Description**: this script computes statistics on two directories with attack graphs which can be used to compare them side by side and decide which attack graphs are more interesting for further analysis. This is one of the most important scripts in this repository.

Statistics that are computed for each corresponding pair of attack graph are:

- *Number of nodes in the first attack graph*
- *Number of edges in the first attack graph*
- *Simplicity of the first attack graph*
- *Whether the first attack graph is complex*
- *Number of objective variants in the first attack graph*
- *Number of nodes in the second attack graph*
- *Number of edges in the second attack graph*
- *Simplicity of the second attack graph*
- *Whether the second attack graph is complex*
- *Number of objective variants in the second attack graph*
- *Absolute difference in number of nodes*
- *Absolute difference in number of edges*
- *Absolute difference in simplicity*
- *Difference in complexity*
- *Absolute difference in number of objective variants*.

Average computed statistics are:

- *Average node count*
- *Average edge count*
- *Average simplicity*.

**Usage**: `./stats-ags-comp.sh path/to/original/AGs path/to/modified/AGs/ [ n | nodes | e | edges | s | simplicity | o | objectives ]` (`[ n | nodes | e | edges | s | simplicity | o | objectives ]` - sort by the difference in nodes, edges, simplicity and objective variants, respectively)

**Example use case**: after running SAGE on CPTC-2017 (or CPTC-2018) before and after merging sinks states, you want to compare the generated attack graphs side-by-side in terms of the size and complexity. You can use various filters in the script (by commenting out or uncommenting lines) to filter only the attack graphs you are interested in (e.g. to get only the attack graphs that have changed their complexity). Here you can use `agf` function from `ag-utils` file to quickly get the .dot files for this script.

### stats-ags.sh

**Description**: this script computes statistics on a directory with attack graphs. This script is primarily used as part of `stats-ags-comp.sh` script, but can also be used on its own.

Statistics that are computed for each attack graph are:

- *Number of nodes*
- *Number of edges*
- *Simplicity* (number of nodes / number of edges, used to measure complexity)
- *Whether the attack graph is complex*
- *Number of discovered objective variants* (i.e. nodes with hexagon shape and salmon colour)

Average computed statistics are:

- *Average node count*
- *Average edge count*
- *Average simplicity*.

**Usage**: `./stats-ags.sh path/to/main/AGs [path/to/other/AGs...]`

**Example use case**: you want to compute statistics on a single directory with attack graphs, for example, before merging sinks or after merging sinks. Here you can use `agf` function from `ag-utils` file to quickly get the .dot files for this script.

### stats-attack-paths.sh

**Description**: this script computes the total number of attack paths for a single attack graph (if multiple attack graphs are provided, then they are processed in turn; same if a single directory is provided). The main use of this script is to compare the number of attack paths for each corresponding pair of AGs in the input directories to see if there are any missing attack paths.

**Usage**: `./stats-attack-paths.sh path/to/AG.dot...`, `./stats-attack-paths.sh path/to/AGs/`, `./stats-attack-paths.sh path/to/original/AGs/ path/to/modified/AGs/`

**Example use case**: after running SAGE on CPTC-2017 (or CPTC-2018) before and after merging sinks states, you want to check whether there are any missing attack paths. The script takes a diff between the two input directories with the attack graphs. If nothing is printed, then the number of found attack paths for each pair of corresponding attack graphs is the same for both versions of SAGE.

### stats-ff.sh

**Description**: this script is used to get the number of red, blue and white states, as well as the number of sink states in the final S-PDFA generated by FlexFringe. This script has only been used when formulating the hypothesis and checking how the final S-PDFA has been affected by merging sinks.

**Usage**: `./stats-ff.sh ExpName`

**Example use case**: after running SAGE on CPTC-2017 (or CPTC-2018) before and after merging sinks states, you want to see how the final S-PDFA has been affected.

### stats-nodes-ags.sh

**Description**: this script computes statistics on the nodes of the attack graphs in the specified directory. This script has only been used when formulating the hypothesis and checking how the node count of attack graphs has been affected by merging sinks.
 
The computed statistics (among all graphs) are:

- *Total number of nodes*
- *Number of unique nodes
- *Total number of sink states*
- *Number of unique sink states*

**Usage**: `./stats-nodes-ags.sh AGs/`

**Example use case**: after running SAGE on CPTC-2017 (or CPTC-2018) before and after merging sinks states, you want to see how the node count of the attack graphs has been affected.

### stats-sinks-ags.sh 

**Description**: this script compares two directories with attack graphs in terms of sink and non-sink nodes. It performs a left outer join on nodes from two directories. If a node is absent in the second directory, "-" will be written, which indicates that this node has been merged. If a node is present in both directories, its status ("sink" or "non-sink") will be printed for both directories.

**Usage**: `./stats-sinks-ags.sh path/to/AGs path/to/AGs`

**Example use case**: after running SAGE on CPTC-2017 (or CPTC-2018) before and after merging sinks states, you want to see which sink nodes have been merged, which sinks became non-sinks and which nodes were non-sinks and remained non-sinks.

### train-lin-reg.sh

**Description**: this script is primarily used inside the `./stats-ags.sh` script to compute the regression line for classification of the attack graphs into complex and non-complex. It is not very useful as a stand-alone script.

**Usage**: `./train-lin-reg.sh path/to/AGs...`

**Example use case**: you want to see which regression line is computed for the classification function of attack graphs based on complexity. The script will output `A B vmin vmax`, where `A + Bx` is the computed regression line, `vmin` and `vmax` are the min and max node counts, as defined in the paper mentioned in the script.


