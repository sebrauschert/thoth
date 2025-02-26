## Analysis Methods for RNA_seq_2024_01

### Overview
Differential expression analysis of treatment vs control samples

### Key Decisions and Quality Control Steps

* Sample-wise PCA clustering:
  - Observation: Treatment samples cluster together except for sample T3
  - Decision: Exclude sample T3
  - Reasoning: T3 clusters with controls, likely sample swap
  - Evidence: plots/PCA_pre_filtering.pdf

* Known pathway markers:
  - Observation: Expected stress response genes upregulated
  - Decision: Results biologically plausible
  - Reasoning: Key marker genes show expected direction of change
  - Evidence: tables/marker_genes_expression.csv


