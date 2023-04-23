# Investigating the modeling assumptions of alert-driven attack graphs

## Background

- Large volumes of intrusion alerts for the forensic analysis of attacks
- Largely manual and labor intensive process, often leading to ‘alert fatigue’ and reduced productivity

## Attack Graphs (AG)

- Modelling attacker strategies for risk assessment
- Are generated from a list of *pre-existing vulnerabilities and network topology*, thus providing a **static** and **hypothetical** view of the network
- Typically **too large** and **do not provide adequate actionable intelligence** to be used in an operational setting

## Alert-driven attack graphs

- A few years ago, Nadeem et al. bridged the gap between static AGs and dynamic alert management by developing 'alert-driven attack graphs'
- Are *learned directly from intrusion alerts* **without any expert knowledge about the target network topology and vulnerabilities**

## SAGE

- The AG generator
- Manages to compress over a million intrusion alerts into less than 500 AGs that show exactly how an attack transpired and allow practitioners to compare attacker strategies
- Uses `suffix-based probabilistic deterministic finite automaton` (S-PDFA) - an interpretable unsupervised sequence learning model - to extract temporal and probabilistic patterns from intrusion alerts that are used to construct the AGs
- S-PDFA model is responsible for:
    1. Accentuating infrequent severe alerts using a suffix-based model
    2. Modelling the semantics of alerts using an interpretable merge criteria

## Challenges

### 1. Different models

- The validation of such models is always tricky as there exists no metric to quantify the quality of an unsupervised model
- One strategy for quality evaluation is to learn different models and pick the one that creates the most intuitive AGs
- In this project, the students will be assigned different modeling assumptions, and they are asked to compare the baseline AGs against the AGs learnt from different models.

### 2. AG prioritization

- Although SAGE manages to compress the alerts by more than 99%, it still produces several hundred AGs.
- How do the practitioners know which AG to look at first?
- Is it based on the attack severity, or alert frequency or something else?
- The students are asked to develop a data-driven prioritization metric [6]

### 3. Quantifying the interpretability of of S-PDFA and AGs

- How can we quantify such a notion?
- What aspects make a model interpretable, and how can one define this notion from a data-driven perspective?
- There exist some works that define interpretability as a measure of information chunks that human cognition that process easily [7]
- Can we define such a metric for AGs?

## References

[1] Hassan, W. U., Guo, S., Li, D., Chen, Z., Jee, K., Li, Z., & Bates, A. (2019, February). Nodoze: Combatting threat alert fatigue with automated provenance triage. In network and distributed systems security symposium.

[2] Noel, S., Elder, M., Jajodia, S., Kalapa, P., O'Hare, S., & Prole, K. (2009, March). Advances in topological vulnerability analysis. In 2009 Cybersecurity Applications & Technology Conference for Homeland Security (pp. 124-129). IEEE.

[3] Nadeem, A., Verwer, S., Moskal, S., & Yang, S. J. (2021). Alert-driven attack graph generation using s-pdfa. IEEE Transactions on Dependable and Secure Computing, 19(2), 731-746.

[4] Nadeem, A., Verwer, S., Moskal, S., & Yang, S. J. (2021, November). Enabling visual analytics via alert-driven attack graphs. In Proceedings of the 2021 ACM SIGSAC Conference on Computer and Communications Security (pp. 2420-2422).

[5] Nadeem, A., Verwer, S., & Yang, S. J. (2022). Suffix-based Finite Automata for Learning Explainable Attacker Strategies. https://hmieai2022.cs.umu.se/wp-content/uploads/2022/05/HMIEAI2022_paper_2853.pdf

[6] Nadeem, A., Dıaz, S. L., & Verwer, S. Critical Path Exploration Dashboard for Alert-driven Attack Graphs. https://vizsec.org/files/2022/vizsec_p4_abstract.pdf

[7] Liu, H., Zhong, C., Alnusair, A., & Islam, S. R. (2021). FAIXID: a framework for enhancing ai explainability of intrusion detection results using data cleaning techniques. Journal of Network and Systems Management, 29(4), 1-30.

[8] Verwer, S., Eyraud, R., & De La Higuera, C. (2014). Pautomac: a probabilistic automata and hidden markov models learning competition. Machine learning, 96(1), 129-154.

[9] Verwer, S., & Hammerschmidt, C. (2022). FlexFringe: Modeling Software Behavior by Learning Probabilistic Automata. arXiv preprint arXiv:2203.16331.

[10] Mouwen, D., Verwer, S., & Nadeem, A. (2022). Robust Attack Graph Generation. arXiv preprint arXiv:2206.07776.

[11] Nadeem, Azqa, et al. SAGE: Intrusion Alert-Driven Attack Graph Extractor. IEEE, 2021.
