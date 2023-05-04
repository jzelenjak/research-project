#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

umask 077

usage="usage: $0 directory1/ directory2/"

ORIGINAL=$1
MODIFIED=$2

echo "Comparing vertices in AGs in graphs $ORIGINAL and $MODIFIED"
echo -ne '\n'

echo "Vertices found by both algorithm: "
comm -12 <(gvpr 'N { print($.name) }' $ORIGINAL | sed 's/ | ID: [0-9]*//g' | sed 's/^\([a-z]*\)$/,\1@/' | tr -d '\n' | tr '@' '\n' | sort) <(gvpr 'N { print($.name) }' $MODIFIED | sed 's/ | ID: [0-9]*//g' | sed 's/^\([a-z]*\)$/,\1@/' | tr -d '\n' | tr '@' '\n' | sort)
echo -ne '\n'

echo "Vertices found only by the original algorithm: "
comm -23 <(gvpr 'N { print($.name) }' $ORIGINAL | sed 's/ | ID: [0-9]*//g' | sed 's/^\([a-z]*\)$/,\1@/' | tr -d '\n' | tr '@' '\n' | sort) <(gvpr 'N { print($.name) }' $MODIFIED | sed 's/ | ID: [0-9]*//g' | sed 's/^\([a-z]*\)$/,\1@/' | tr -d '\n' | tr '@' '\n' | sort)
echo -ne '\n'

echo "Vertices found only by the modified algorithm: "
comm -13 <(gvpr 'N { print($.name) }' $ORIGINAL | sed 's/ | ID: [0-9]*//g' | sed 's/^\([a-z]*\)$/,\1@/' | tr -d '\n' | tr '@' '\n' | sort) <(gvpr 'N { print($.name) }' $MODIFIED | sed 's/ | ID: [0-9]*//g' | sed 's/^\([a-z]*\)$/,\1@/' | tr -d '\n' | tr '@' '\n' | sort)

