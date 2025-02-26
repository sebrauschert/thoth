## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = FALSE  # Don't evaluate code chunks by default
)

## ----installation-------------------------------------------------------------
# # Install required dependencies if not already installed
# required_packages <- c("usethis", "yaml", "cli", "digest", "rmarkdown", "tools")
# for (pkg in required_packages) {
#   if (!requireNamespace(pkg, quietly = TRUE)) {
#     install.packages(pkg)
#   }
# }
# 
# # Install thoth from GitHub
# if (!requireNamespace("devtools", quietly = TRUE)) {
#   install.packages("devtools")
# }
# devtools::install_github("sebrauschert/thoth")

## ----setup--------------------------------------------------------------------
# library(thoth)

## -----------------------------------------------------------------------------
# decision_file <- initialize_decision_tree(
#   analysis_id = "RNA_seq_2024_01",
#   analyst = "Jane Smith",
#   description = "Differential expression analysis of treatment vs control samples"
# )

## -----------------------------------------------------------------------------
# # Record a quality control decision
# record_decision(
#   file_path = decision_file,
#   check = "Sample-wise PCA clustering",
#   observation = "Treatment samples cluster together except for sample T3",
#   decision = "Exclude sample T3",
#   reasoning = "T3 clusters with controls, likely sample swap",
#   evidence = "plots/PCA_pre_filtering.pdf"
# )
# 
# # Record a biological validation step
# record_decision(
#   file_path = decision_file,
#   check = "Known pathway markers",
#   observation = "Expected stress response genes upregulated",
#   decision = "Results biologically plausible",
#   reasoning = "Key marker genes show expected direction of change",
#   evidence = "tables/marker_genes_expression.csv"
# )

## -----------------------------------------------------------------------------
# # Generate methods section
# methods_text <- generate_methods_section(decision_file)
# cat(methods_text)

## -----------------------------------------------------------------------------
# # Export to markdown
# export_decision_tree(decision_file, format = "md")
# 
# # Export to HTML (requires rmarkdown)
# if (requireNamespace("rmarkdown", quietly = TRUE)) {
#   export_decision_tree(decision_file, format = "html")
# }

