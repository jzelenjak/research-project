#!/bin/bash
# Some helpful utility functions to resolve AG names
# An AG name is assumed to be in the following format: `victim|mcat|mServ`, e.g. `10.0.0.153|DATA_EXFILTRATION|Unknown`
#
# NB! The .dot files are by default deleted during the execution of SAGE
#      To prevent deletion, comment out lines 2850-2851 in sage.py, or set DOCKER to False

# Resolve an AG name to .dot file(s)
agf() {
    [[ $# -ne 1 ]] && { echo "usage: agfc victim|mcat|mServ" >&2 ; return ; }

    graph="$1"
    victim=$(cut -d '|' -f1 <<< "$graph")
    objective=$(cut -d '|' -f2,3 <<< $graph | tr -d '|' | tr -d '_' | tr -d '-' | sed 's/DoS/DOS/g' | sed 's/ORG\./ORG/g')

    find . -type f -name '*.dot' | grep -- "${victim}-" | grep -- "-${objective}\."
}

# Resolve an AG name to .dot file(s), filter based on the second argument (e.g. directory) and copy to the clipboard
agfc() {
    [[ $# -ne 2 ]] && { echo "usage: agfc victim|mcat|mServ filter_str" >&2 ; return ; }

    agf "$1" | grep "$2" | xsel --clipboard
}

# Resolve an AG name to .png file(s) and show the images
ag() {
    [[ $# -ne 1 ]] && { echo "usage: agfc victim|mcat|mServ" >&2 ; return ; }

    graph="$1"
    victim=$(cut -d '|' -f1 <<< "$graph")
    objective=$(cut -d '|' -f2,3 <<< $graph | tr -d '|' | tr -d '_' | tr -d '-' | sed 's/DoS/DOS/g' | sed 's/ORG\./ORG/g')

    find . -type f -name '*.png' | grep -- "${victim}-" | grep -- "-${objective}\." | sed 's/^.*$/xdg-open &/' | sh
}

# Resolve an AG name to .png file(s) from the combined directory (AGs side-by-side) and show the images
ag-comb() {
    [[ $# -ne 1 ]] && { echo "usage: agfc victim|mcat|mServ" >&2 ; return ; }

    graph="$1"
    victim=$(cut -d '|' -f1 <<< "$graph")
    objective=$(cut -d '|' -f2,3 <<< $graph | tr -d '|' | tr -d '_' | tr -d '-' | sed 's/DoS/DOS/g' | sed 's/ORG\./ORG/g')

    find comb*/ -type f -name '*.png' | grep -- "${victim}-" | grep -- "-${objective}\." | sed 's/^.*$/xdg-open &/' | sh
}

ag-diff() {
    [[ $# -ne 1 ]] && { echo "usage: agfc victim|mcat|mServ" >&2 ; return ; }

    [[ -f ./diff-nodes.sh ]] && agf "$1" | xargs ./diff-nodes.sh
}

export -f agf
export -f agfc
export -f ag
export -f ag-comb