#' Create a New Analytics Project
#'
#' Sets up a new analytics project with standardized structure and configuration
#' for reproducible analysis using DVC, Docker, renv, and Quarto.
#'
#' @param path Character. The path where the project should be created.
#' @param use_dvc Logical. Whether to initialize DVC. Default is TRUE.
#' @param use_docker Logical. Whether to set up Docker configuration. Default is TRUE.
#' @param use_renv Logical. Whether to initialize renv. Default is TRUE.
#' @param git_init Logical. Whether to initialize git repository. Default is TRUE.
#' @param open Logical. Whether to open the new project in RStudio. Default is TRUE.
#'
#' @return Invisibly returns the path to the created project.
#' @export
#'
#' @examples
#' \dontrun{
#' create_analytics_project("my_analysis")
#' }
create_analytics_project <- function(path,
                                   use_dvc = TRUE,
                                   use_docker = TRUE,
                                   use_renv = TRUE,
                                   git_init = TRUE,
                                   open = rlang::is_interactive()) {
  # Check if required system tools are available
  check_system_requirements(use_dvc, use_docker)
  
  # Normalize path
  path <- normalizePath(path, mustWork = FALSE)
  
  # Create the basic project using usethis
  usethis::create_project(
    path = path,
    rstudio = TRUE,  # Always create as RStudio project
    open = FALSE     # We'll handle opening later
  )
  
  # Change to project directory for remaining setup
  old_wd <- setwd(path)
  on.exit(setwd(old_wd))

  # Create standard directory structure
  dirs <- c(
    "data/raw",
    "data/processed",
    "R",
    "reports",
    "docker"
  )
  
  lapply(dirs, dir.create, recursive = TRUE, showWarnings = FALSE)

  # Initialize Git if requested (after project creation)
  if (git_init) {
    system2("git", args = c("init"))
    write_gitignore()
  }

  # Initialize DVC if requested
  if (use_dvc) {
    system2("dvc", args = c("init"))
    setup_dvc_tracking()
  }

  # Set up Docker if requested
  if (use_docker) {
    setup_docker()
  }
  
  # Initialize renv if requested
  if (use_renv) {
    renv::init()
    
    # Install thoth in the new project
    cli::cli_alert_info("Installing thoth package in the project environment...")
    
    # Create a script to install thoth in the project environment
    setup_script <- file.path(path, "setup_thoth.R")
    writeLines(c(
      "# Setup script for installing thoth",
      "renv::init()",
      "renv::install('sebrauschert/thoth')",
      "renv::snapshot()"
    ), setup_script)
    
    # Run the installation script in a new R session
    system2("Rscript", args = c(setup_script))
    unlink(setup_script)
  }

  # Create README
  write_readme(path)

  # Set up Quarto template
  setup_quarto_template()

  # Success message
  cli::cli_alert_success("Analytics project successfully created at {.path {path}}")
  
  # Open the project if requested
  if (open) {
    if (rstudioapi::isAvailable()) {
      rstudioapi::openProject(path, newSession = TRUE)
    } else {
      # Set working directory and active project
      setwd(path)
      usethis::proj_set(path)
      cli::cli_alert_info("Project activated. Working directory changed to: {.path {path}}")
    }
  }
  
  invisible(path)
}

#' Check System Requirements
#'
#' @param use_dvc Logical. Whether DVC is required
#' @param use_docker Logical. Whether Docker is required
#' @keywords internal
check_system_requirements <- function(use_dvc, use_docker) {
  if (use_dvc) {
    dvc_exists <- system2("which", "dvc", stdout = NULL, stderr = NULL) == 0
    if (!dvc_exists) {
      cli::cli_abort("DVC is not installed. Please install it first: https://dvc.org/doc/install")
    }
  }
  
  if (use_docker) {
    docker_exists <- system2("which", "docker", stdout = NULL, stderr = NULL) == 0
    if (!docker_exists) {
      cli::cli_abort("Docker is not installed. Please install it first: https://docs.docker.com/get-docker/")
    }
  }
}

#' Write Default .gitignore File
#' @keywords internal
write_gitignore <- function() {
  gitignore_content <- c(
    ".Rproj.user/",
    ".Rhistory",
    ".RData",
    ".Ruserdata",
    "*.Rproj",
    "/data/raw/*",
    "/data/processed/*",
    "!/data/raw/.gitkeep",
    "!/data/processed/.gitkeep",
    ".env",
    "renv/library/",
    "renv/python/",
    "renv/staging/"
  )
  writeLines(gitignore_content, ".gitignore")
}

#' Set up DVC Tracking
#' @keywords internal
setup_dvc_tracking <- function() {
  # Create .dvcignore
  dvcignore_content <- c(
    "# Add patterns of files dvc should ignore, which are specific to your project",
    "# For example: *.png, *.log"
  )
  writeLines(dvcignore_content, ".dvcignore")
  
  # Create .gitignore if it doesn't exist
  if (!file.exists(".gitignore")) {
    gitignore_content <- c(
      ".Rproj.user/",
      ".Rhistory",
      ".RData",
      ".Ruserdata",
      "*.Rproj",
      # Data directories but allow .dvc files
      "/data/raw/*",
      "/data/processed/*",
      "!/data/raw/.gitkeep",
      "!/data/processed/.gitkeep",
      "!/data/raw/**/*.dvc",     # Allow .dvc files in raw data directory
      "!/data/processed/**/*.dvc", # Allow .dvc files in processed data directory
      "!*.dvc",                  # Generally allow .dvc files
      ".env",
      "renv/library/",
      "renv/python/",
      "renv/staging/",
      "/.dvc/cache"             # Ignore DVC cache
    )
    writeLines(gitignore_content, ".gitignore")
  }
  
  # Create .gitkeep files
  dir.create("data/raw", recursive = TRUE, showWarnings = FALSE)
  dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)
  file.create("data/raw/.gitkeep")
  file.create("data/processed/.gitkeep")
}

#' Set up Docker Configuration
#' @keywords internal
setup_docker <- function() {
  # Get current R version
  r_version <- paste0(R.version$major, ".", R.version$minor)
  
  dockerfile_content <- c(
    sprintf("FROM rocker/rstudio:%s", r_version),
    "",
    "# Install system dependencies",
    "RUN apt-get update && apt-get install -y \\",
    "    python3-pip \\",
    "    && rm -rf /var/lib/apt/lists/*",
    "",
    "# Install DVC",
    "RUN pip3 install dvc",
    "",
    "# Create working directory",
    "WORKDIR /project",
    "",
    "# Copy project files",
    "COPY . /project/",
    "",
    "# Install R packages",
    "RUN R -e 'install.packages(\"renv\")'",
    "RUN R -e 'renv::restore()'",
    "",
    "# Set permissions for RStudio user",
    "RUN chown -R rstudio:rstudio /project",
    "",
    "# Command to keep the container running",
    "CMD [\"/init\"]"
  )
  writeLines(dockerfile_content, "docker/Dockerfile")
  
  # Create docker-compose.yml
  docker_compose_content <- c(
    "services:",
    "  rstudio:",
    "    build: .",
    "    ports:",
    "      - \"8787:8787\"",
    "    environment:",
    "      - PASSWORD=rstudio",
    "      - ROOT=TRUE",
    "    volumes:",
    "      - .:/project",
    "    user: rstudio"
  )
  writeLines(docker_compose_content, "docker/docker-compose.yml")
  
  cli::cli_alert_success("Docker configuration created with R version {r_version}")
}

#' Write Project README
#' @keywords internal
write_readme <- function(project_name) {
  readme_content <- c(
    paste0("# ", basename(project_name)),
    "",
    "## Project Overview",
    "",
    "Describe your project here.",
    "",
    "## Project Structure",
    "",
    "```",
    "+-- data/           # Data files",
    "|   +-- raw/       # Raw data, tracked by DVC",
    "|   +-- processed/ # Processed data, tracked by DVC",
    "+-- R/             # R scripts",
    "+-- reports/       # Analysis reports (Quarto)",
    "+-- docker/        # Docker configuration",
    "```",
    "",
    "## Setup",
    "",
    "1. Clone this repository",
    "2. Install dependencies: `renv::restore()`",
    "3. Pull data: `dvc pull`",
    "",
    "## Usage",
    "",
    "Describe how to use the project here."
  )
  writeLines(readme_content, "README.md")
}

#' Set up Quarto Template
#' @keywords internal
setup_quarto_template <- function() {
  # Create reports directory if it doesn't exist
  dir.create("reports", showWarnings = FALSE)
  
  # Create a basic Quarto template
  quarto_template <- c(
    "---",
    "title: \"Analysis Report\"",
    "author: \"Your Name\"",
    "date: \"`r Sys.Date()`\"",
    "format:",
    "  html:",
    "    theme: cosmo",
    "    toc: true",
    "    code-fold: true",
    "---",
    "",
    "```{r setup, include=FALSE}",
    "knitr::opts_chunk$set(",
    "  echo = TRUE,",
    "  message = FALSE,",
    "  warning = FALSE",
    ")",
    "```",
    "",
    "## Overview",
    "",
    "## Data Import and Processing",
    "",
    "## Analysis",
    "",
    "## Results",
    "",
    "## Conclusions"
  )
  writeLines(quarto_template, "reports/template.qmd")
} 