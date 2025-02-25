# thoth 0.0.0.9000

## New features

* Added DVC tracking functionality with tidyverse integration:
  * `dvc_track()` for tracking files after writing
  * `write_csv_dvc()` for writing and tracking CSV files
  * `write_rds_dvc()` for writing and tracking RDS files
* Added comprehensive test suite for DVC tracking functions
* Added vignette demonstrating DVC tracking functionality

## Documentation improvements

* Updated pkgdown site with DVC tracking documentation
* Added examples for all DVC tracking functions
* Improved function documentation with more detailed descriptions

## Bug fixes

* None (initial release)

## Initial development version

* Added core functionality for creating reproducible analytics projects
* Implemented data version control with DVC integration
* Added Git integration for version control
* Implemented Docker containerization
* Added dependency management with renv
* Implemented decision tracking functionality
* Added customizable reporting with Quarto
* Added metrics functions for model evaluation 