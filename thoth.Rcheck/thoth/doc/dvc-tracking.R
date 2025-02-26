## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = Sys.which("dvc") != ""  # Only evaluate if DVC is installed
)

has_dvc <- Sys.which("dvc") != ""
if (!has_dvc) {
  message("Note: Code chunks in this vignette require DVC to be installed.")
  message("Visit https://dvc.org/doc/install for installation instructions.")
}

## ----setup--------------------------------------------------------------------
library(thoth)

## -----------------------------------------------------------------------------
# Check if DVC is available
dvc_available <- Sys.which("dvc") != ""
if (!dvc_available) {
  message("DVC is not installed. Please install it first.")
} else {
  message("DVC is installed and ready to use!")
}

## ----eval=FALSE---------------------------------------------------------------
# library(thoth)
# create_analytics_project(
#   "my_analysis",
#   use_dvc = TRUE  # DVC is enabled by default
# )

