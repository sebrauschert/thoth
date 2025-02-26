# thoth: Reproducible Analytics Framework with Data Version Control

<!-- badges: start -->
[![R-CMD-check](https://github.com/sebrauschert/thoth/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/sebrauschert/thoth/actions/workflows/R-CMD-check.yaml)
[![test-coverage](https://github.com/sebrauschert/thoth/actions/workflows/test-coverage.yaml/badge.svg)](https://github.com/sebrauschert/thoth/actions/workflows/test-coverage.yaml)
[![pkgdown](https://github.com/sebrauschert/thoth/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/sebrauschert/thoth/actions/workflows/pkgdown.yaml)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

## Overview

thoth is a comprehensive framework for setting up reproducible analytics projects in R. It integrates data version control (DVC), containerization (Docker), dependency management (renv), and customizable reporting (Quarto) to implement best practices for project organization, workflow management, and reproducible research.

## System Requirements

The package requires several external tools:

* **DVC (Data Version Control)** >= 2.0.0
  - Required for data version control features
  - [Installation instructions](https://dvc.org/doc/install)
  - Note: The package will work without DVC installed, creating mock .dvc files instead

* **Python** >= 3.7
  - Required for DVC
  - [Installation instructions](https://www.python.org/downloads/)

* **Docker** >= 20.10.0 (Optional)
  - Required for containerization features
  - [Installation instructions](https://docs.docker.com/get-docker/)

## Installation

You can install the development version of thoth from GitHub:

```r
# install.packages("devtools")
devtools::install_github("sebrauschert/thoth")
```

## Key Features

* **Project Setup**
  - Standardized project structures
  - Version control initialization
  - Dependency management setup

* **Data Version Control**
  - Track large data files
  - Create reproducible pipelines
  - Track metrics and plots

* **Containerization**
  - Reproducible environments
  - Package analyses for distribution

* **Reporting**
  - Customizable report templates
  - Decision tracking
  - Methods section generation

## Getting Started

1. Install system requirements (DVC, Python, Docker)
2. Install thoth:
   ```r
   devtools::install_github("sebrauschert/thoth")
   ```
3. Create a new project:
   ```r
   library(thoth)
   create_analytics_project("my_analysis")
   ```
4. Read the vignettes:
   ```r
   browseVignettes("thoth")
   ```

## Usage Example

```r
library(thoth)

# Create a new analytics project
create_analytics_project("my_analysis")

# Track data files with DVC
dvc_track("data/raw/dataset.csv")

# Write and track CSV files
write_csv_dvc(mtcars, "data/processed/mtcars.csv")

# Write and track RDS files
write_rds_dvc(model, "models/random_forest.rds")
```

## Documentation

* [Package website](https://sebrauschert.github.io/thoth/)
* [Getting started guide](https://sebrauschert.github.io/thoth/articles/thoth.html)
* [DVC tracking guide](https://sebrauschert.github.io/thoth/articles/dvc-tracking.html)
* [Custom templates guide](https://sebrauschert.github.io/thoth/articles/custom-templates.html)

## Contributing

Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on how to contribute to this project.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.


<sub>Thoth icon by [Freepik](https://www.freepik.com)</sub>