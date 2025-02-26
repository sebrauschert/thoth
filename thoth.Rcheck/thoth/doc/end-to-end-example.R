## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = FALSE
)

## ----setup--------------------------------------------------------------------
# library(thoth)
# library(tidyverse)
# library(tidymodels)
# 
# # Create a new project
# create_analytics_project(
#   "iris_analysis",
#   use_dvc = TRUE,
#   use_docker = TRUE,
#   git_init = TRUE
# )
# 
# # Change to the project directory
# setwd("iris_analysis")

## ----raw_data-----------------------------------------------------------------
# # Save raw iris data
# iris %>%
#   as_tibble() %>%
#   write_csv_dvc(
#     "data/raw/iris.csv",
#     message = "Add raw iris dataset"
#   )

## ----processing---------------------------------------------------------------
# # Read and process data
# processed_data <- read_csv("data/raw/iris.csv") %>%
#   janitor::clean_names() %>%
#   mutate(
#     species = as.factor(species),
#     # Scale numeric columns properly
#     across(where(is.numeric), function(x) {
#       as.numeric(scale(x))
#     })
#   )
# 
# # Create train/test split
# set.seed(123)
# split <- initial_split(processed_data, prop = 0.8)
# train_data <- training(split)
# test_data <- testing(split)
# 
# # Save processed datasets with DVC
# train_data %>%
#   write_csv_dvc(
#     "data/processed/train.csv",
#     message = "Add processed training data",
#     stage_name = "prepare_data",
#     deps = "data/raw/iris.csv",
#     params = list(
#       train_prop = 0.8,
#       seed = 123
#     )
#   )
# 
# test_data %>%
#   write_csv_dvc(
#     "data/processed/test.csv",
#     message = "Add processed test data"
#   )

## ----training-----------------------------------------------------------------
# # Train random forest model
# rf_spec <- rand_forest(
#   trees = 500,
#   mtry = 3
# ) %>%
#   set_engine("ranger") %>%
#   set_mode("classification")
# 
# rf_fit <- rf_spec %>%
#   fit(
#     species ~ .,
#     data = train_data
#   )
# 
# # Save model with DVC
# rf_fit %>%
#   write_rds_dvc(
#     "models/rf_model.rds",
#     message = "Add trained random forest model",
#     stage_name = "train_model",
#     deps = "data/processed/train.csv",
#     params = list(
#       n_trees = 500,
#       mtry = 3
#     )
#   )

## ----evaluation---------------------------------------------------------------
# # Make predictions
# predictions <- rf_fit %>%
#   predict(test_data) %>%
#   bind_cols(test_data)
# 
# # Calculate metrics
# metrics <- predictions %>%
#   metrics(truth = species, estimate = .pred_class)
# 
# # Create and save confusion matrix plot
# predictions %>%
#   conf_mat(truth = species, estimate = .pred_class) %>%
#   autoplot() %>%
#   ggplot2::ggsave(
#     filename = "plots/confusion_matrix.png",
#     plot = .,
#     width = 8,
#     height = 6
#   )
# 
# # Save metrics with DVC
# metrics %>%
#   write_csv_dvc(
#     "metrics/model_metrics.csv",
#     message = "Add model evaluation metrics",
#     stage_name = "evaluate_model",
#     deps = c(
#       "models/rf_model.rds",
#       "data/processed/test.csv"
#     ),
#     metrics = TRUE
#   )

## ----decisions----------------------------------------------------------------
# # Initialize decision tree
# decision_file <- initialize_decision_tree(
#   analysis_id = "iris_classification",
#   analyst = "Data Scientist",
#   description = "Classification of iris species using random forest"
# )
# 
# # Record data processing decision
# record_decision(
#   decision_file,
#   check = "Data preprocessing",
#   observation = "All features are on different scales",
#   decision = "Scale all numeric features",
#   reasoning = "Random forest performance can be affected by feature scales",
#   evidence = "data/processed/train.csv"
# )
# 
# # Record model selection decision
# record_decision(
#   decision_file,
#   check = "Model selection",
#   observation = "Non-linear relationships between features",
#   decision = "Use random forest classifier",
#   reasoning = "RF can capture non-linear relationships and feature interactions",
#   evidence = "models/rf_model.rds"
# )
# 
# # Create reports directory if it doesn't exist
# dir.create("reports", showWarnings = FALSE)
# 
# # Export decision tree
# export_decision_tree(
#   decision_file,
#   format = "html",
#   output_path = "reports/decisions.html"
# )

## ----reproduce----------------------------------------------------------------
# system2("dvc", "repro")

