pkgname <- "thoth"
source(file.path(R.home("share"), "R", "examples-header.R"))
options(warn = 1)
library('thoth')

base::assign(".oldSearch", base::search(), pos = 'CheckExEnv')
base::assign(".old_wd", base::getwd(), pos = 'CheckExEnv')
cleanEx()
nameEx("apply_template_to_report")
### * apply_template_to_report

flush(stderr()); flush(stdout())

### Name: apply_template_to_report
### Title: Apply Template to Report
### Aliases: apply_template_to_report

### ** Examples

## Not run: 
##D apply_template_to_report("reports/analysis.qmd", "company_template")
## End(Not run)



cleanEx()
nameEx("conf_mat")
### * conf_mat

flush(stderr()); flush(stdout())

### Name: conf_mat
### Title: Create a confusion matrix
### Aliases: conf_mat

### ** Examples

## Not run: 
##D library(dplyr)
##D data(mtcars)
##D # Create a binary outcome
##D mtcars <- mtcars %>% 
##D   mutate(vs_factor = factor(vs))
##D # Fit a model
##D model <- glm(vs ~ mpg + cyl, data = mtcars, family = "binomial")
##D # Make predictions
##D preds <- predict(model, type = "response")
##D # Create prediction data frame
##D pred_data <- mtcars %>%
##D   mutate(pred = factor(ifelse(preds > 0.5, 1, 0)))
##D # Calculate confusion matrix
##D conf_mat(pred_data, truth = vs_factor, estimate = pred)
## End(Not run)



cleanEx()
nameEx("create_analytics_project")
### * create_analytics_project

flush(stderr()); flush(stdout())

### Name: create_analytics_project
### Title: Create a New Analytics Project
### Aliases: create_analytics_project

### ** Examples

## Not run: 
##D create_analytics_project("my_analysis")
## End(Not run)



cleanEx()
nameEx("create_quarto_template")
### * create_quarto_template

flush(stderr()); flush(stdout())

### Name: create_quarto_template
### Title: Create Custom Quarto Template
### Aliases: create_quarto_template

### ** Examples

## Not run: 
##D create_quarto_template(
##D   template_name = "company_template",
##D   logo_path = "path/to/logo.png",
##D   primary_color = "#FF0000"
##D )
## End(Not run)



cleanEx()
nameEx("dvc_track")
### * dvc_track

flush(stderr()); flush(stdout())

### Name: dvc_track
### Title: Track files with DVC after writing
### Aliases: dvc_track

### ** Examples

## Not run: 
##D data |>
##D   readr::write_csv("data/processed/mydata.csv") |>
##D   dvc_track("Updated processed data", push = TRUE)
## End(Not run)



cleanEx()
nameEx("git_add")
### * git_add

flush(stderr()); flush(stdout())

### Name: git_add
### Title: Add Files to Git
### Aliases: git_add

### ** Examples

## Not run: 
##D git_add("analysis.R")
##D git_add(c("data/results.csv", "plots/figure1.png"))
##D git_add(".", force = FALSE)  # add all changes
## End(Not run)



cleanEx()
nameEx("git_branch")
### * git_branch

flush(stderr()); flush(stdout())

### Name: git_branch
### Title: Create a New Git Branch
### Aliases: git_branch

### ** Examples

## Not run: 
##D git_branch("feature/new-analysis")
##D git_branch("hotfix/bug-123", checkout = FALSE)
## End(Not run)



cleanEx()
nameEx("git_branch_list")
### * git_branch_list

flush(stderr()); flush(stdout())

### Name: git_branch_list
### Title: List Git Branches
### Aliases: git_branch_list

### ** Examples

## Not run: 
##D git_branch_list()
##D git_branch_list(all = TRUE)  # include remote branches
## End(Not run)



cleanEx()
nameEx("git_checkout")
### * git_checkout

flush(stderr()); flush(stdout())

### Name: git_checkout
### Title: Checkout a Git Branch
### Aliases: git_checkout

### ** Examples

## Not run: 
##D git_checkout("main")
##D git_checkout("feature/new-analysis", create = TRUE)
## End(Not run)



cleanEx()
nameEx("git_commit")
### * git_commit

flush(stderr()); flush(stdout())

### Name: git_commit
### Title: Commit Changes to Git
### Aliases: git_commit

### ** Examples

## Not run: 
##D git_commit("Add analysis script")
##D git_commit("Update results", all = TRUE)
## End(Not run)



cleanEx()
nameEx("git_log")
### * git_log

flush(stderr()); flush(stdout())

### Name: git_log
### Title: Get Git Log
### Aliases: git_log

### ** Examples

## Not run: 
##D git_log()
##D git_log(n = 20, oneline = FALSE)  # detailed log
## End(Not run)



cleanEx()
nameEx("git_pull")
### * git_pull

flush(stderr()); flush(stdout())

### Name: git_pull
### Title: Pull Changes from Git Remote
### Aliases: git_pull

### ** Examples

## Not run: 
##D git_pull()
##D git_pull("origin", "main")
## End(Not run)



cleanEx()
nameEx("git_push")
### * git_push

flush(stderr()); flush(stdout())

### Name: git_push
### Title: Push Changes to Git Remote
### Aliases: git_push

### ** Examples

## Not run: 
##D git_push()
##D git_push("origin", "feature/new-analysis")
## End(Not run)



cleanEx()
nameEx("git_status")
### * git_status

flush(stderr()); flush(stdout())

### Name: git_status
### Title: Get Git Status
### Aliases: git_status

### ** Examples

## Not run: 
##D git_status()
##D git_status(short = FALSE)  # detailed output
## End(Not run)



cleanEx()
nameEx("metrics")
### * metrics

flush(stderr()); flush(stdout())

### Name: metrics
### Title: Calculate model performance metrics
### Aliases: metrics

### ** Examples

## Not run: 
##D library(dplyr)
##D data(mtcars)
##D # Create a binary outcome
##D mtcars <- mtcars %>% 
##D   mutate(vs_factor = factor(vs))
##D # Fit a model
##D model <- glm(vs ~ mpg + cyl, data = mtcars, family = "binomial")
##D # Make predictions
##D preds <- predict(model, type = "response")
##D # Create prediction data frame
##D pred_data <- mtcars %>%
##D   mutate(pred = factor(ifelse(preds > 0.5, 1, 0)))
##D # Calculate metrics
##D metrics(pred_data, truth = vs_factor, estimate = pred)
## End(Not run)



cleanEx()
nameEx("write_csv_dvc")
### * write_csv_dvc

flush(stderr()); flush(stdout())

### Name: write_csv_dvc
### Title: Write a CSV file and track it with DVC
### Aliases: write_csv_dvc

### ** Examples

## Not run: 
##D # Simple tracking
##D data |> write_csv_dvc(
##D   "data/processed/results.csv",
##D   message = "Add processed results",
##D   push = TRUE
##D )
##D 
##D # As part of a pipeline
##D data |> write_csv_dvc(
##D   "data/processed/features.csv",
##D   message = "Add feature matrix",
##D   stage_name = "feature_engineering",
##D   deps = "data/raw/input.csv",
##D   params = list(n_components = 10),
##D   push = TRUE
##D )
## End(Not run)



cleanEx()
nameEx("write_rds_dvc")
### * write_rds_dvc

flush(stderr()); flush(stdout())

### Name: write_rds_dvc
### Title: Write RDS with DVC tracking
### Aliases: write_rds_dvc

### ** Examples

## Not run: 
##D # Simple tracking
##D model |> write_rds_dvc(
##D   "models/model.rds",
##D   message = "Updated model",
##D   push = TRUE
##D )
##D 
##D # As part of a pipeline
##D model |> write_rds_dvc(
##D   "models/rf_model.rds",
##D   message = "Save trained random forest model",
##D   stage_name = "train_model",
##D   deps = c("data/processed/training.csv", "R/train_model.R"),
##D   params = list(ntree = 500),
##D   push = TRUE
##D )
## End(Not run)



### * <FOOTER>
###
cleanEx()
options(digits = 7L)
base::cat("Time elapsed: ", proc.time() - base::get("ptime", pos = 'CheckExEnv'),"\n")
grDevices::dev.off()
###
### Local variables: ***
### mode: outline-minor ***
### outline-regexp: "\\(> \\)?### [*]+" ***
### End: ***
quit('no')
