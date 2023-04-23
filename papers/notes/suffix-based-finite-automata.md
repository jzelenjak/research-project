# Suffix-based Finite Automata for Learning Explainable Attacker Strategies

## Motivation

- Learning about attacker behaviour = manual and expert knowledge-driven task (system vulnerabilities + network topology, static) => 'alert fatigue'
- `Attack Graph` (AG) - graphical representation of attacker strategies; it shows all the paths that attackers might use during network penetration

## Alert-driven attack graphs, SAGE and S-PDFA

- `Alert-driven attack graphs` (ADAG) - learned directly from intrusion alerts, no expert input is needed
- `SAGE` - an interpretable sequence learning pipeline which constructs AGs from the observed intrusion alerts. No expert knowledge is needed
- `S-PDFA` - models the temporal and probabilistic relationships between alerts (FlexFringe automaton learning framework); individual graphs extracted from S-PDFA are per victim host per objective

## Constraints addressed by S-PDFA

1. *Alert-type imbalance* - infrequent severe alerts vs frequent non-severe alerts. S-PDFA highlights infrequent severe alerts (appear at the end of the sequences), while preserving all the low-severity alerts

2. *Modeling context* - same alert signature in different attack strategies. Alert context is captured by the S-PDFA state identifiers (Alergia heuristic for state merging - states with similar futures and pasts are merged, states leading to different outcomes are not)

3. *Interpretable model* - `Markovian property` (the input transition symbols of a state are unique) + `sink states` (states that occur too infrequently to learn from; low-severity sinks are removed from the model). States are *milestones* achieved by an attacker. Algorithmic transparency

## Evaluation

- Several multi-member teams exploit a common fictitious network; a minimal set of network-agnostic features is derived from the resulting intrusion alerts
- Collectively: 1425k alerts -> 401 AGs
- Attackers exploit shorter paths after having already found a longer one
- Intuitive layout to compare attacker strategies

## References

Nadeem, A., Verwer, S., & Yang, S. J. (2022). Suffix-based Finite Automata for Learning Explainable Attacker Strategies. https://hmieai2022.cs.umu.se/wp-content/uploads/2022/05/HMIEAI2022_paper_2853.pdf
