## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = FALSE
)

## ----setup--------------------------------------------------------------------
# library(thoth)
# library(tidyverse)
# library(edgeR)
# library(limma)
# library(statmod)  # Required for edgeR
# library(ComplexHeatmap)
# 
# # Create new project
# create_analytics_project(
#   "rnaseq_analysis",
#   use_dvc = TRUE,
#   use_docker = TRUE,
#   git_init = TRUE
# )
# 
# # Change to project directory
# setwd("rnaseq_analysis")

## ----raw_data-----------------------------------------------------------------
# # Simulate count data
# set.seed(42)
# n_genes <- 10000
# n_samples <- 8
# 
# # Create counts matrix
# counts <- matrix(
#   rnbinom(n_genes * n_samples, mu = 100, size = 1),
#   nrow = n_genes,
#   ncol = n_samples
# )
# 
# # Add row and column names
# rownames(counts) <- paste0("gene_", 1:n_genes)
# colnames(counts) <- paste0("sample_", 1:n_samples)
# 
# # Create sample metadata
# sample_info <- data.frame(
#   sample = colnames(counts),
#   group = rep(c("control", "treatment"), each = 4),
#   batch = rep(c("A", "B"), 4)
# )
# 
# # Save and track raw data with DVC
# counts |>
#   as.data.frame() |>
#   rownames_to_column("gene_id") |>
#   write_csv_dvc(
#     "data/raw/counts.csv",
#     message = "Add raw count data"
#   )
# 
# sample_info |>
#   write_csv_dvc(
#     "data/raw/sample_info.csv",
#     message = "Add sample metadata"
#   )

## ----decisions----------------------------------------------------------------
# # Initialize decision tracking
# decision_file <- initialize_decision_tree(
#   analysis_id = "rnaseq_2024",
#   analyst = "Data Scientist",
#   description = "Differential expression analysis of treatment vs control"
# )

## ----create_dge---------------------------------------------------------------
# # Read data
# counts_df <- read_csv("data/raw/counts.csv")
# sample_info <- read_csv("data/raw/sample_info.csv")
# 
# # Create DGEList
# dge <- DGEList(
#   counts = counts_df |> column_to_rownames("gene_id"),
#   group = sample_info$group
# )
# 
# # Add batch information
# dge$samples$batch <- sample_info$batch

## ----qc-----------------------------------------------------------------------
# # Calculate library sizes and CPM
# lib_sizes <- dge$samples$lib.size
# cpms <- cpm(dge)
# 
# # Filter low expression genes
# keep <- filterByExpr(dge, group = dge$samples$group)
# dge_filtered <- dge[keep, ]
# 
# # Record filtering decision
# record_decision(
#   decision_file,
#   check = "Gene filtering",
#   observation = sprintf(
#     "Removed %d low expression genes",
#     sum(!keep)
#   ),
#   decision = "Filter using filterByExpr()",
#   reasoning = "Remove genes with consistently low counts",
#   evidence = "plots/gene_expression_density.png"
# )
# 
# # Save filtered data
# dge_filtered$counts |>
#   as.data.frame() |>
#   rownames_to_column("gene_id") |>
#   write_csv_dvc(
#     "data/processed/filtered_counts.csv",
#     message = "Add filtered count data",
#     stage_name = "filter_genes",
#     deps = c(
#       "data/raw/counts.csv",
#       "data/raw/sample_info.csv"
#     ),
#     params = list(
#       min_cpm = 1,
#       min_samples = 4
#     )
#   )
# 
# # Normalization
# dge_filtered <- calcNormFactors(dge_filtered)
# 
# # Record normalization decision
# record_decision(
#   decision_file,
#   check = "Normalization",
#   observation = "Library sizes vary between samples",
#   decision = "Apply TMM normalization",
#   reasoning = "Account for composition bias",
#   evidence = NULL
# )

## ----qc_plots-----------------------------------------------------------------
# # MDS plot
# limma::plotMDS(dge_filtered) |>
#   ggplot2::ggsave(
#     "plots/mds_plot.png",
#     width = 8,
#     height = 6
#   )
# 
# # Record MDS observation
# record_decision(
#   decision_file,
#   check = "Sample clustering",
#   observation = "Samples cluster by treatment with some batch effect",
#   decision = "Include batch in design matrix",
#   reasoning = "Account for technical variation",
#   evidence = "plots/mds_plot.png"
# )

## ----de_analysis--------------------------------------------------------------
# # Create design matrix
# design <- model.matrix(
#   ~batch + group,
#   data = dge_filtered$samples
# )
# 
# # Fit model
# fit <- lmFit(
#   voom(dge_filtered, design),
#   design
# )
# fit <- eBayes(fit)
# 
# # Get results
# results <- topTable(
#   fit,
#   coef = "grouptreatment",
#   number = Inf
# ) |>
#   rownames_to_column("gene_id")
# 
# # Save results with DVC
# results |>
#   write_csv_dvc(
#     "data/processed/de_results.csv",
#     message = "Add differential expression results",
#     stage_name = "de_analysis",
#     deps = "data/processed/filtered_counts.csv",
#     params = list(
#       adj_p_threshold = 0.05,
#       lfc_threshold = 1
#     ),
#     metrics = TRUE  # Track as DVC metrics
#   )
# 
# # Record analysis decisions
# record_decision(
#   decision_file,
#   check = "Differential expression",
#   observation = sprintf(
#     "Found %d DE genes (FDR < 0.05, |logFC| > 1)",
#     sum(results$adj.P.Val < 0.05 & abs(results$logFC) > 1)
#   ),
#   decision = "Use voom-limma pipeline",
#   reasoning = "Account for mean-variance relationship",
#   evidence = "data/processed/de_results.csv"
# )

## ----visualization------------------------------------------------------------
# # Create volcano plot
# results |>
#   ggplot(aes(x = logFC, y = -log10(adj.P.Val))) +
#   geom_point(
#     aes(color = adj.P.Val < 0.05 & abs(logFC) > 1),
#     alpha = 0.6
#   ) +
#   scale_color_manual(values = c("grey", "red")) +
#   theme_minimal() +
#   labs(
#     title = "Volcano Plot",
#     x = "log2 Fold Change",
#     y = "-log10 Adjusted P-value"
#   ) |>
#   ggsave(
#     "plots/volcano_plot.png",
#     width = 10,
#     height = 8
#   )
# 
# # Create heatmap of top DE genes
# top_genes <- results |>
#   filter(adj.P.Val < 0.05, abs(logFC) > 1) |>
#   slice_head(n = 50) |>
#   pull(gene_id)
# 
# # Get normalized expression for top genes
# expr_mat <- voom(dge_filtered, design)$E[top_genes, ]
# 
# # Save heatmap
# png("plots/heatmap.png", width = 800, height = 1000)
# Heatmap(
#   expr_mat,
#   name = "Expression",
#   column_split = dge_filtered$samples$group,
#   show_row_names = FALSE
# )
# dev.off()

## ----export-------------------------------------------------------------------
# # Export decision tree
# export_decision_tree(
#   decision_file,
#   format = "html",
#   output_path = "reports/analysis_decisions.html"
# )

