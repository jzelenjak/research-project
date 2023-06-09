#!/bin/bash
# Parses the medium- and high-severity episodes printed by SAGE in the `break_into_subbehaviors` method, and creates transitions (like edges in an AG).
#
# The assumed format of an episode is: `attacker_ip \t victim_ip \t st \t et \t mcat mserv`
# Example: 10.0.254.30	10.0.0.80	04/11/17, 12:56:23	04/11/17, 12:56:28	DATA EXFILTRATION http
#
# NB! By default, SAGE does not print episodes.
#     Add some way of printing them in the above-mentioned format in the `break_into_subbehaviors` method.

set -euo pipefail
IFS=$'\n\t'

umask 077

usage() {
    echo -e "Usage: $0 expName-episodes.txt"
}

[[ $# -ne 1 ]] && { usage >&2 ; exit 1 ; }

! [[ -f "$1" ]] && { echo "$0: file $1 does not exist" >&2 ; exit 1 ; }

episodes=$(awk -F '\t' '{ if ( $1 ~ /10.0.254/ && $2 ~ /10.0.254/ ) { print $2 "\t" $1 "\t" $3 "\t" $4 "\t" $5 } else { print $0 }}' "$1" |  # This fix is here because SAGE swaps attacker and victim, which should not happen in this particular case
                sort -s -t $'\t' -k2,2 -k1,1 -k3,3 |  # Sort based on the victim, then the attacker and then the start time of the episode
                tr -d ',' |                           # Remove unnecessary commas
                tr $'\t' ',')                         # Separate fields with commas instead of tabs

# 10.0.254.35,10.0.99.225,04/11/17 13:22:54,04/11/17 13:22:58,DATA EXFILTRATION http,10.0.254.35,10.0.99.225,04/11/17 13:22:54,04/11/17 13:22:58,DATA EXFILTRATION http
paste -d ',' <(echo -e "$episodes") <(echo -e "$episodes" | sed '1d' ) |                            # Combine episodes and episodes shifted by one up (to make transitions)
    awk -F',' '$2 == $7 { print $1 "," $2 "," $4 "," $8 "," $5 " -> " $10 }' |                      # Remove wrong transitions (victim cannot change) and print the transition: attacker,victim,end_prev,start_next,episode1 -> episode2 
    awk -F ',' '                                                                                    # This entire pipeline is essentially a "GROUP_BY" in SQL
        NR == 1 { prev_attacker = $1; prev_victim = $2 ; print $0 }                                 # First line: only initialise prev_attacker and prev_victim
        NR > 1 {                                                                                    # Here, compare the attacker and victim of the current line to those of the previous line
            if ($1 != prev_attacker && $2 == prev_victim) {                                         # Same victim but different attacker -> separate attack the attack
                print "\n" $0
            } else if ($2 != prev_victim) {                                                         # Different victim -> separate even more, as this is a completely different "context"
                print "\n" "\n" $0
            } else {                                                                                # Simply print the other lines with no changes
                print $0
            }
            prev_attacker = $1                                                                      # Update prev_attacker and prev_victim with those of the current line
            prev_victim = $2
        }' |
        sed 's/,/\t/g'                                                                              # Separate with tabs for better readability
