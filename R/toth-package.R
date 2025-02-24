#' toth: Reproducible Analytics Framework with Data Version Control
#'
#' @description
#' A comprehensive framework for setting up reproducible analytics projects with
#' integrated version control for data using 'DVC' (Data Version Control),
#' containerization using 'Docker', dependency management using 'renv', and
#' customizable reporting using 'Quarto'.
#'
#' @section Key Features:
#' \itemize{
#'   \item Project organization and structure
#'   \item Data version control with DVC
#'   \item Containerization with Docker
#'   \item Dependency management with renv
#'   \item Customizable reporting with Quarto
#' }
#'
#' @section Main Functions:
#' \itemize{
#'   \item \code{\link{create_analytics_project}}: Create a new analytics project
#'   \item \code{\link{dvc_track}}: Track files with DVC
#'   \item \code{\link{write_csv_dvc}}: Write and track CSV files
#'   \item \code{\link{write_rds_dvc}}: Write and track RDS files
#' }
#'
#' @docType package
#' @name toth-package
#' @aliases toth
#'
#' @importFrom cli cli_alert_success cli_abort
#' @importFrom digest digest
#' @importFrom readr write_csv
#' @importFrom renv init restore
#' @importFrom usethis create_project
#'
"_PACKAGE"

# Define package level options
.onLoad <- function(libname, pkgname) {
  # Set default options if needed
  op <- options()
  op.toth <- list(
    toth.dvc.path = Sys.which("dvc"),
    toth.docker.path = Sys.which("docker")
  )
  toset <- !(names(op.toth) %in% names(op))
  if (any(toset)) options(op.toth[toset])
  
  invisible()
}

.onAttach <- function(libname, pkgname) {
  packageStartupMessage("Welcome to toth! For help, see: https://sebrauschert.github.io/toth/")
} 