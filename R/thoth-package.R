#' thoth: Reproducible Analytics Framework with Data Version Control
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
#' @name thoth-package
#' @aliases thoth
#'
#' @importFrom cli cli_alert_success cli_abort cli_alert_info cli_div cli_text cli_end
#' @importFrom digest digest
#' @importFrom readr write_csv
#' @importFrom renv init restore
#' @importFrom usethis create_project
#' @importFrom janitor clean_names
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
  packageStartupMessage(cli::col_blue(cli::symbol$info), " Did you know? ", random_fact)
  packageStartupMessage(cli::col_cyan("*"), " For help, see: ", 
                       cli::style_hyperlink("https://sebrauschert.github.io/thoth/", 
                                           "https://sebrauschert.github.io/thoth/"))
} 