# thoth: Reproducible Analytics Framework with Data Version Control

<!-- badges: start -->
[![R-CMD-check](https://github.com/sebrauschert/thoth/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/sebrauschert/thoth/actions/workflows/R-CMD-check.yaml)
[![test-coverage](https://github.com/sebrauschert/thoth/actions/workflows/test-coverage.yaml/badge.svg)](https://github.com/sebrauschert/thoth/actions/workflows/test-coverage.yaml)
[![pkgdown](https://github.com/sebrauschert/thoth/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/sebrauschert/thoth/actions/workflows/pkgdown.yaml)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

## Why Thoth?

In ancient Egyptian mythology, Thoth was the god of wisdom, writing, and knowledge. As the divine scribe, he was said to have documented everything, maintaining perfect records of all actions and their consequences. This package embodies these principles by providing a framework that meticulously tracks every aspect of your analytical work - from data to decisions.

## Overview

`thoth` is a comprehensive framework for creating reproducible analytics projects in R. Modern data analysis requires more than just code version control; it demands reproducible environments, tracked data, and documented decision-making. `thoth` addresses these challenges by seamlessly integrating data version control (DVC), containerization (Docker), dependency management (renv), and customizable reporting (Quarto).

The framework provides a standardized project structure while remaining flexible enough to accommodate various analytical workflows. It automatically tracks large data files, creates reproducible pipelines, and maintains a clear record of analytical decisions. This systematic approach ensures that your research is not only reproducible but also transparent and well-documented.

## Core Features

The framework enhances reproducibility through four key components:

Data Version Control enables tracking of large data files and creates reproducible pipelines with metrics and plot versioning. This ensures that your data transformations are traceable and reproducible.

Containerization through Docker guarantees that your analysis runs in a consistent environment, making it easier to share and reproduce results across different systems.

Project Organization provides a standardized yet flexible structure for your analytics projects, with integrated version control and dependency management through renv.

Documentation and Reporting offers customizable report templates and automated tracking of analytical decisions, making it easier to generate comprehensive methods sections for publications.

## System Requirements

To use `thoth`, you'll need:

* **DVC (Data Version Control)** >= 2.0.0
  - Required for data version control features
  - [Installation instructions](https://dvc.org/doc/install)
  - Note: The package will work without DVC, creating mock .dvc files instead

* **Python** >= 3.7
  - Required for DVC
  - [Installation instructions](https://www.python.org/downloads/)

* **Docker** >= 20.10.0 (Optional)
  - Required for containerization features
  - [Installation instructions](https://docs.docker.com/get-docker/)

## Installation

You can install the development version of `thoth` directly from GitHub:

```r
# install.packages("devtools")
devtools::install_github("sebrauschert/thoth")
```

## Quick Start

Getting started with `thoth` is straightforward. After installing the package, you can create a new analytics project with a single command:

```r
library(thoth)

# Create a new project with all features enabled
create_analytics_project(
  "my_analysis",
  use_dvc = TRUE,      # Enable data version control
  use_docker = TRUE    # Enable containerization
)

# Track your data files
dvc_track("data/raw/dataset.csv")

# Save and track processed data
write_csv_dvc(
  processed_data,
  "data/processed/results.csv",
  message = "Add processed results"
)

# Track your trained models
write_rds_dvc(
  model,
  "models/random_forest.rds",
  message = "Add trained model"
)
```

## Documentation

Comprehensive documentation is available to help you get started:

* [Package website](https://sebrauschert.github.io/thoth/)
* [Getting started guide](https://sebrauschert.github.io/thoth/articles/thoth.html)
* [DVC tracking guide](https://sebrauschert.github.io/thoth/articles/dvc-tracking.html)
* [Custom templates guide](https://sebrauschert.github.io/thoth/articles/custom-templates.html)

## Contributing

We welcome contributions! Whether it's bug reports, feature requests, or code contributions, please see our [contribution guidelines](CONTRIBUTING.md) for details on how to get involved.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

<sub>Thoth icon by [Freepik](https://www.freepik.com)</sub>