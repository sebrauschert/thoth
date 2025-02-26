#' thoth: Reproducible Analytics Framework with Data Version Control
#'
#' @description
#' Provides a framework for setting up reproducible analytics projects with integrated
#' version control for data using DVC (Data Version Control), containerization using
#' Docker, dependency management using renv, and customizable reporting using Quarto.
#' Implements best practices for project organization, workflow management, and
#' reproducible research.
#'
#' @section System Requirements:
#' This package requires several external tools to be installed:
#'
#' * DVC (Data Version Control) >= 2.0.0
#'   - Required for data version control features
#'   - Installation: Visit https://dvc.org/doc/install
#'   - Note: The package will work without DVC installed, but will create mock .dvc
#'     files instead of actual version control
#'
#' * Python >= 3.7
#'   - Required for DVC
#'   - Installation: Visit https://www.python.org/downloads/
#'
#' * Docker >= 20.10.0
#'   - Required for containerization features
#'   - Installation: Visit https://docs.docker.com/get-docker/
#'   - Note: Docker features are optional
#'
#' @section Package Features:
#' * Project Setup
#'   - Create standardized project structures
#'   - Initialize version control
#'   - Set up dependency management
#'
#' * Data Version Control
#'   - Track large data files
#'   - Create reproducible pipelines
#'   - Track metrics and plots
#'
#' * Containerization
#'   - Create reproducible environments
#'   - Package analyses for distribution
#'
#' * Reporting
#'   - Customizable report templates
#'   - Decision tracking
#'   - Methods section generation
#'
#' @section Getting Started:
#' To get started with thoth:
#'
#' 1. Install system requirements (DVC, Python, Docker)
#' 2. Create a new project:
#'    ```r
#'    library(thoth)
#'    create_analytics_project("my_analysis")
#'    ```
#' 3. Read the vignettes:
#'    ```r
#'    browseVignettes("thoth")
#'    ```
#'
#' @docType package
#' @name thoth-package
#' @aliases thoth
#'
#' @importFrom cli cli_alert_success cli_abort cli_alert_info cli_div cli_text cli_end
#' @importFrom digest digest
#' @importFrom readr write_csv
#' @importFrom renv init restore
#' @importFrom usethis create_project
#' @importFrom janitor clean_names
#' @importFrom fs dir_create path_join
#' @importFrom glue glue
#' @importFrom magrittr %>%
#' @importFrom fs path
#'
#' @keywords internal
"_PACKAGE"

# Define package level options
.onLoad <- function(libname, pkgname) {
  # Set default options if needed
  op <- options()
  op.thoth <- list(
    thoth.dvc.path = Sys.which("dvc"),
    thoth.docker.path = Sys.which("docker")
  )
  toset <- !(names(op.thoth) %in% names(op))
  if (any(toset)) options(op.thoth[toset])
  
  invisible()
}

.onAttach <- function(libname, pkgname) {
  # Check DVC installation
  has_dvc <- Sys.which("dvc") != ""
  
  # Thoth facts
  thoth_facts <- c(
    "Thoth was the ancient Egyptian god of wisdom, writing, and magic.",
    "Thoth was often depicted with the head of an ibis or a baboon.",
    "Thoth was believed to have invented hieroglyphic writing.",
    "Thoth was the scribe of the gods and keeper of divine records.",
    "Thoth was said to have written the 'Book of the Dead' and the '42 Books of Knowledge'.",
    "Thoth was the measurer of time and the inventor of mathematics.",
    "Thoth was the mediator in disputes between gods, especially between Set and Horus.",
    "Thoth was associated with the moon and was sometimes called the 'Lord of Time'.",
    "Thoth was believed to have the power to grant wisdom and knowledge to humans.",
    "Thoth was the patron of scribes, scholars, and magicians in ancient Egypt."
  )
  
  # Select a random fact
  random_fact <- sample(thoth_facts, 1)
  
  # Create a stylish startup message that is suppressible
  packageStartupMessage(cli::col_green(cli::symbol$tick), " Welcome to ", 
                       cli::col_cyan("thoth"), "! The reproducible analytics framework")
  
  # Add DVC installation status message
  if (!has_dvc) {
    packageStartupMessage(cli::col_yellow(cli::symbol$warning), 
                         " DVC is not installed. Some features will be limited.")
    packageStartupMessage("  Visit ", cli::style_hyperlink("https://dvc.org/doc/install",
                                                          "https://dvc.org/doc/install"),
                         " to install DVC for full functionality.")
  }
  
  packageStartupMessage(cli::col_blue(cli::symbol$info), " Did you know? ", random_fact)
  packageStartupMessage(cli::col_cyan("*"), " For help, see: ", 
                       cli::style_hyperlink("https://sebrauschert.github.io/thoth/", 
                                           "https://sebrauschert.github.io/thoth/"))
} 