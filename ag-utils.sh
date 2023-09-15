#!/bin/bash
# Some helpful utility functions to resolve AG names.
# An AG name is assumed to be in the following format: `victim|mcat|mServ`, e.g. `10.0.0.153|DATA_EXFILTRATION|Unknown` (althogh, this should also work: `10.0.0.100-DATAEXFILTRATIONmicrosoftds`).
#
# NB! Don't forget to source this file initially and after every modification (i.e. run `source ag-utils.sh` or `. ag-utils.sh`).
#     You can also source this file in your ~/.bashrc, so that you don't forget to do it.
#
# NB! Some functions are based on .dot files, which are by default deleted during the execution of SAGE.
#      To prevent the deletion, use the --keep-files option when running SAGE.

# This is the prefix used in every AG file name (ExpName-prefix-victim-mcatmserv)
prefix="-attack-graph-for-victim-"

# If the AG name is not in the assumed format (i.e. `victim|mcat|mServ`), convert it to the assumed format (this is a 'private' function)
_convert_ag_name(){
    graph="$1"
    if ! grep ".*|.*|.*" <<< "$graph" 1> /dev/null ; then
        graph=$(sed 's/^.*'"$prefix"'\(.*\)\.dot.*$/\1/' <<< "$graph" | sed 's/^\([0-9.]\+\)-/\1|/' | sed 's/\([A-Z]\+\)/\1|/' | tr -s '|')  # Separate victim, mcat and mserv with a '|' symbol
    fi
    echo "$graph"
}

# Resolve an AG name to .dot file(s)
agf() {
    # Check if exactly one argument is provided
    [[ $# -ne 1 ]] && { echo "Usage: agf 'victim|mcat|mServ'" >&2 ; return ; }

    # Get the AG name (in the consistent format)
    graph=$(_convert_ag_name "$1")

    # Get the victim and the objective from the AG name (`victim|mcat|mServ`)
    victim=$(cut -d '|' -f1 <<< "$graph")
    objective=$(cut -d '|' -f2,3 <<< "$graph" | tr -d '|' | tr -d '_' | tr -d '-' | sed 's/DoS/DOS/g' | sed 's/ORG\./ORG/g')

    # Find the .dot file(s) with the provided AG name
    find . -type f -name '*.dot' | grep -- "${victim}-" | grep -- "-${objective}\."
}

# Resolve an AG name to .dot file(s), filter based on the second argument (e.g. directory) and copy to the clipboard
agfc() {
    # Check if exactly two arguments are provided
    [[ $# -ne 2 ]] && { echo "Usage: agfc 'victim|mcat|mServ' 'filter_str'" >&2 ; return ; }

    # Find the .dot file(s) with the provided AG name, filter based on the second argument and copy to the clipboard
    agf "$1" | grep "$2" | xsel --clipboard
}

# Resolve an AG name to .png file(s) and show the images
ag() {
    # Check if exactly one argument is provided
    [[ $# -ne 1 ]] && { echo "Usage: ag 'victim|mcat|mServ'" >&2 ; return ; }

    # Get the AG name (in the consistent format)
    graph=$(_convert_ag_name "$1")

    # Get the victim and the objective from the AG name (`victim|mcat|mServ`)
    victim=$(cut -d '|' -f1 <<< "$graph")
    objective=$(cut -d '|' -f2,3 <<< $graph | tr -d '|' | tr -d '_' | tr -d '-' | sed 's/DoS/DOS/g' | sed 's/ORG\./ORG/g')

    # Find the .png file(s) with the provided AG name and open them with `xdg-open` command
    find . -type f -name '*.png' | grep -- "${victim}-" | grep -- "-${objective}\." | sed 's/^.*$/xdg-open &/' | sh
}

# Resolve an AG name to .png file(s) from the combined directory (AGs side-by-side) and show the images
ag-comb() {
    # Check if exactly one argument is provided
    [[ $# -ne 1 ]] && { echo "Usage: ag-comb 'victim|mcat|mServ'" >&2 ; return ; }

    # Get the AG name (in the consistent format)
    graph=$(_convert_ag_name "$1")

    # Get the victim and the objective from the AG name (`victim|mcat|mServ`)
    victim=$(cut -d '|' -f1 <<< "$graph")
    objective=$(cut -d '|' -f2,3 <<< $graph | tr -d '|' | tr -d '_' | tr -d '-' | sed 's/DoS/DOS/g' | sed 's/ORG\./ORG/g')

    # Find the .png file(s) with the provided AG name *in the combined directory* (i.e. starts with 'comb') and open them with `xdg-open` command
    find comb*/ -type f -name '*.png' | grep -- "${victim}-" | grep -- "-${objective}\." | sed 's/^.*$/xdg-open &/' | sh
}

# Resolve an AG name to .dot files and find the differences in nodes between these AGs
# NB! This is a pure shortcut, use it when you know that the AG name can only be resolved in exactly two .dot files
ag-diff() {
    # Check if exactly one argument is provided
    [[ $# -ne 1 ]] && { echo "Usage: ag-diff 'victim|mcat|mServ'" >&2 ; return ; }

    # If the ./diff-nodes.sh script exists, resolve the AG name to .dot files and run the script with these .dot files 
    [[ -f ./diff-nodes.sh ]] && agf "$1" | xargs ./diff-nodes.sh
}

# Export functions from this file
export -f agf
export -f agfc
export -f ag
export -f ag-comb
export -f ag-diff

