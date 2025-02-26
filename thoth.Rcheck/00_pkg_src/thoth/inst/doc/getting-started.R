## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = FALSE
)

## -----------------------------------------------------------------------------
# # install.packages("devtools")
# devtools::install_github("sebrauschert/thoth")

## -----------------------------------------------------------------------------
# library(thoth)
# library(tidyverse)
# 
# # Create a new project with all features enabled
# create_analytics_project(
#   "my_project",
#   use_dvc = TRUE,
#   use_docker = TRUE,
#   use_quarto = TRUE
# )

## -----------------------------------------------------------------------------
# # Example data processing pipeline
# raw_data <- read_csv("data/raw/dataset.csv")
# 
# processed_data <- raw_data |>
#   mutate(
#     date = as.Date(date),
#     value = as.numeric(value)
#   ) |>
#   filter(!is.na(value)) |>
#   # Save processed data with DVC tracking
#   write_csv_dvc(
#     "data/processed/cleaned_data.csv",
#     "Cleaned and processed raw data"
#   )
# 
# # Continue with analysis
# summary_stats <- processed_data |>
#   group_by(category) |>
#   summarise(
#     mean_value = mean(value),
#     sd_value = sd(value)
#   ) |>
#   # Save summary statistics with DVC tracking
#   write_csv_dvc(
#     "data/processed/summary_stats.csv",
#     "Generated summary statistics"
#   )

## -----------------------------------------------------------------------------
# # Train a model
# model <- lm(value ~ date + category, data = processed_data)
# 
# # Save model with DVC tracking
# model |>
#   write_rds_dvc(
#     "models/linear_model.rds",
#     "Trained linear regression model"
#   )
# 
# # Make predictions and save results
# predictions <- model |>
#   predict(newdata = new_data) |>
#   as_tibble() |>
#   write_csv_dvc(
#     "results/model_predictions.csv",
#     "Generated model predictions"
#   )

## -----------------------------------------------------------------------------
# # Raw data pipeline
# raw_survey_data |>
#   write_csv_dvc(
#     "data/raw/survey_2024.csv",
#     "Added raw survey data for 2024"
#   )
# 
# # Processed data pipeline
# cleaned_survey_data |>
#   write_csv_dvc(
#     "data/processed/survey_2024_clean.csv",
#     "Added cleaned survey data"
#   ) |>
#   create_features() |>
#   write_csv_dvc(
#     "data/processed/survey_2024_features.csv",
#     "Added feature engineered dataset"
#   )
# 
# # Model pipeline
# final_model |>
#   write_rds_dvc(
#     "models/survey_2024_model.rds",
#     "Final predictive model with accuracy: 0.92"
#   )

## -----------------------------------------------------------------------------
# # Install a new package
# renv::install("tidymodels")
# 
# # Update lockfile
# renv::snapshot()
# 
# # Restore project environment
# renv::restore()

## -----------------------------------------------------------------------------
# # Create a new template
# create_quarto_template(
#   "company_template",
#   primary_color = "#0054AD",
#   secondary_color = "#00B4E0",
#   logo_path = "path/to/logo.png"
# )
# 
# # Apply template to a report
# apply_template_to_report(
#   "reports/analysis.qmd",
#   "company_template"
# )

## -----------------------------------------------------------------------------
# # Keep raw data separate
# raw_data |>
#   write_csv_dvc(
#     "data/raw/experiment_data.csv",
#     "Raw experimental data"
#   )
# 
# # Store processed data with clear naming
# processed_data |>
#   write_csv_dvc(
#     "data/processed/experiment_cleaned.csv",
#     "Cleaned experimental data"
#   )
# 
# # Save models with version info
# model |>
#   write_rds_dvc(
#     "models/xgboost_v2.rds",
#     "XGBoost model v2 (accuracy: 0.92)"
#   )

## -----------------------------------------------------------------------------
# # Safe writing function
# safe_write <- function(data, path, message) {
#   tryCatch(
#     write_csv_dvc(data, path, message),
#     error = function(e) {
#       warning("Failed to save data: ", e$message)
#       NULL
#     }
#   )
# }
# 
# # Using purrr::safely
# safe_write_dvc <- safely(write_csv_dvc)
# result <- safe_write_dvc(data, "data/output.csv", "Saved output")

