# toth: Reproducible Analytics Framework with Data Version Control

<!-- badges: start -->
[![R-CMD-check](https://github.com/sebrauschert/toth/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/sebrauschert/toth/actions/workflows/R-CMD-check.yaml)
[![test-coverage](https://github.com/sebrauschert/toth/actions/workflows/test-coverage.yaml/badge.svg)](https://github.com/sebrauschert/toth/actions/workflows/test-coverage.yaml)
[![pkgdown](https://github.com/sebrauschert/toth/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/sebrauschert/toth/actions/workflows/pkgdown.yaml)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

## Overview

`toth` is a comprehensive R package that provides a framework for setting up and managing reproducible analytics projects. It integrates several key components:

- Data Version Control (DVC) for managing large data files
- Git integration for code version control
- Docker containerization for environment reproducibility
- renv for R package dependency management
- Quarto for beautiful, reproducible reports
- Decision tracking for documenting analytical choices

This package is still in active development and should be used with caution.

```r
# Install from GitHub
remotes::install_github("sebrauschert/toth")
```

# Why is this package called "`toth`"?
`toth` is named after the ancient Egyptian deity of wisdom and writing and embodies the essence of preserving and documenting knowledge. Just as Toth was revered for recording the deeds of the living and maintaining cosmic order, this R package ensures analytical integrity through comprehensive version control of code, data and analytical decisions. By seamlessly integrating DVC, Git, and Docker, Toth aims to create a robust framework for reproducible analytics, making it effortless to track data lineage, manage dependencies, and share reproducible environments. Whether you're collaborating on a team project or maintaining consistency in your solo analyses, `toth` serves as your faithful scribe, ensuring that every step of your analytical journey is documented, reproducible, and trustworthy.

### System Requirements

- R (>= 4.1.0)
- Python (>= 3.7)
- DVC (>= 2.0.0)
- Docker (>= 20.10.0)
- git

## Quick Start

```r
library(toth)

# Create a new analytics project
create_analytics_project(
  "my_analysis",
  use_dvc = TRUE,
  use_docker = TRUE,
  git_init = TRUE
)
```

This creates a standardized project structure:

```
my_analysis/
├── data/
│   ├── raw/        # Raw data, tracked by DVC
│   └── processed/  # Processed data, tracked by DVC
├── R/              # R scripts
├── reports/        # Analysis reports (Quarto)
├── docker/         # Docker configuration
├── renv/           # Package management
├── .dvc/          # DVC configuration
└── .git/          # Git repository
```

## Key Features

### 1. Data Version Control

Track and version large data files:

```r
# Track CSV files with DVC
data |> write_csv_dvc(
  "data/processed/results.csv",
  message = "Add processed results"
)

# Track R objects
model |> write_rds_dvc(
  "models/model.rds",
  message = "Save trained model"
)

# Create DVC pipelines
data |> write_csv_dvc(
  "data/processed/features.csv",
  stage_name = "feature_engineering",
  deps = "data/raw/input.csv",
  params = list(n_components = 10)
)
```

### 2. Git Integration

Manage version control directly from R:

```r
# Check status
git_status()

# Create and switch to a feature branch
git_checkout("feature/new-analysis", create = TRUE)

# Stage and commit changes
git_add("analysis.R")
git_commit("Add analysis script")

# Push to remote
git_push()
```

### 3. Decision Tracking

Document analytical decisions:

```r
# Initialize decision tracking
decision_file <- initialize_decision_tree(
  analysis_id = "my_analysis",
  analyst = "Data Scientist",
  description = "Analysis of experimental data"
)

# Record decisions
record_decision(
  decision_file,
  check = "Data preprocessing",
  observation = "Found outliers in variable X",
  decision = "Remove outliers beyond 3 SD",
  reasoning = "Standard practice in field",
  evidence = "plots/outlier_analysis.png"
)

# Export decisions
export_decision_tree(decision_file, format = "html")
```

### 4. Docker Integration

Containerize your analysis:

```r
# Project is automatically set up with Docker
# Dockerfile and docker-compose.yml are created in docker/
```

The Docker setup includes:
- RStudio server
- DVC installation
- Project dependencies
- Proper user permissions

### 5. Quarto Integration

Create beautiful reports:

```r
# Set up Quarto template
setup_quarto_template()

# Apply template to report
apply_template_to_report("analysis.qmd")
```

## Documentation

Visit our [website](https://sebrauschert.github.io/toth/) for comprehensive documentation:

- [Getting Started Guide](https://sebrauschert.github.io/toth/articles/getting-started.html)
- [Data Version Control](https://sebrauschert.github.io/toth/articles/dvc-tracking.html)
- [Git Integration](https://sebrauschert.github.io/toth/articles/git-integration.html)
- [Decision Tracking](https://sebrauschert.github.io/toth/articles/decision-tracking.html)
- [Docker Setup](https://sebrauschert.github.io/toth/articles/docker-setup.html)
- [End-to-End Example](https://sebrauschert.github.io/toth/articles/end-to-end-example.html)

## Contributing

Contributions are welcome! Please read our [Contributing Guidelines](CONTRIBUTING.md) for details on how to submit pull requests, report issues, and contribute to the project.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.


<sub>Toth icon by [Freepik](https://www.freepik.com)</sub>