#' Decision Tracking Functions
#' @name decision_tracking
#' @description Functions for tracking and documenting human decisions in analyses
#'
#' @importFrom yaml write_yaml read_yaml
#' @importFrom cli cli_alert_success cli_alert_info
#' @importFrom digest digest
#' @importFrom usethis ui_done ui_info
#'
NULL

#' Initialize a Decision Tree
#'
#' @param analysis_id Character string identifying the analysis
#' @param analyst Character string with analyst name
#' @param description Character string describing the analysis
#' @param path Character string specifying where to save the decision tree
#'
#' @return Invisibly returns the path to the created decision tree file
#' @export
initialize_decision_tree <- function(analysis_id, analyst, description, path = "decisions") {
  # Create decisions directory if it doesn't exist
  dir.create(path, showWarnings = FALSE, recursive = TRUE)
  
  # Create basic decision tree structure
  decision_tree <- list(
    analysis_id = analysis_id,
    analyst = analyst,
    description = description,
    date_created = as.character(Sys.time()),
    decisions = list()
  )
  
  # Create file path
  file_path <- file.path(path, paste0(analysis_id, "_decision_tree.yaml"))
  
  # Save initial decision tree
  yaml::write_yaml(decision_tree, file = file_path)
  
  cli::cli_alert_success("Decision tree initialized at {file_path}")
  invisible(file_path)
}

#' Record a Decision
#'
#' @param file_path Path to the decision tree YAML file
#' @param check Character string describing what was checked
#' @param observation Character string describing what was observed
#' @param decision Character string describing the decision made
#' @param reasoning Character string explaining the reasoning
#' @param evidence Character string pointing to supporting evidence (e.g., plot path)
#'
#' @return Invisibly returns the updated decision tree
#' @export
record_decision <- function(file_path, check, observation, decision, reasoning, evidence = NULL) {
  # Read existing decision tree
  decision_tree <- yaml::read_yaml(file_path)
  
  # Create new decision entry
  new_decision <- list(
    id = digest::digest(paste0(check, Sys.time()), algo = "sha1"),
    timestamp = as.character(Sys.time()),
    check = check,
    observation = observation,
    decision = decision,
    reasoning = reasoning,
    evidence = evidence
  )
  
  # Add new decision to tree
  decision_tree$decisions[[length(decision_tree$decisions) + 1]] <- new_decision
  
  # Save updated decision tree
  yaml::write_yaml(decision_tree, file = file_path)
  
  cli::cli_alert_success("Decision recorded successfully")
  invisible(decision_tree)
}

#' Generate Methods Section from Decision Tree
#'
#' @param file_path Path to the decision tree YAML file
#' @param format Output format ("markdown" or "text")
#'
#' @return Character string containing the methods section
#' @export
generate_methods_section <- function(file_path, format = "markdown") {
  # Read decision tree
  decision_tree <- yaml::read_yaml(file_path)
  
  # Create header
  methods <- sprintf("## Analysis Methods for %s\n\n", decision_tree$analysis_id)
  
  # Add analysis description
  methods <- paste0(methods, 
                   "### Overview\n",
                   decision_tree$description, "\n\n")
  
  # Add decisions section
  methods <- paste0(methods, "### Key Decisions and Quality Control Steps\n\n")
  
  # Add each decision
  for (decision in decision_tree$decisions) {
    methods <- paste0(methods,
                     "* ", decision$check, ":\n",
                     "  - Observation: ", decision$observation, "\n",
                     "  - Decision: ", decision$decision, "\n",
                     "  - Reasoning: ", decision$reasoning, "\n",
                     if (!is.null(decision$evidence)) paste0("  - Evidence: ", decision$evidence, "\n"),
                     "\n")
  }
  
  if (format == "text") {
    methods <- gsub("#", "", methods)
  }
  
  return(methods)
}

#' Export Decision Tree to Various Formats
#'
#' @param file_path Path to the decision tree YAML file
#' @param format Output format ("html", "pdf", or "md")
#' @param output_path Path where to save the output file
#'
#' @return Invisibly returns the path to the exported file
#' @export
export_decision_tree <- function(file_path, format = "md", output_path = NULL) {
  # Generate methods section
  methods <- generate_methods_section(file_path, format = "markdown")
  
  # If no output path specified, create one based on input file
  if (is.null(output_path)) {
    base_name <- tools::file_path_sans_ext(file_path)
    output_path <- paste0(base_name, ".", format)
  }
  
  # Store current working directory
  original_wd <- getwd()
  on.exit(setwd(original_wd), add = TRUE)  # Ensure we restore the working directory
  
  # Get absolute paths
  output_path <- normalizePath(output_path, mustWork = FALSE)
  output_dir <- dirname(output_path)
  
  # Create output directory if it doesn't exist
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  }
  
  # Change to the output directory
  setwd(output_dir)
  
  # Write output based on format
  switch(format,
         "md" = writeLines(methods, basename(output_path)),
         "html" = {
           # Create temporary directory for intermediates
           temp_dir <- tempfile("rmd_")
           dir.create(temp_dir)
           on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)
           
           # Create temporary Rmd file in temp directory
           temp_rmd <- file.path(temp_dir, "temp.Rmd")
           writeLines(c("---", "title: \"Decision Tree\"", "---", "", methods), temp_rmd)
           
           # Render with explicit intermediate directory
           rmarkdown::render(temp_rmd, 
                           output_file = basename(output_path),
                           output_format = "html_document",
                           intermediates_dir = temp_dir,
                           quiet = TRUE)
         },
         "pdf" = {
           # Create temporary directory for intermediates
           temp_dir <- tempfile("rmd_")
           dir.create(temp_dir)
           on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)
           
           # Create temporary Rmd file in temp directory
           temp_rmd <- file.path(temp_dir, "temp.Rmd")
           writeLines(c("---", "title: \"Decision Tree\"", "---", "", methods), temp_rmd)
           
           # Render with explicit intermediate directory
           rmarkdown::render(temp_rmd, 
                           output_file = basename(output_path),
                           output_format = "pdf_document",
                           intermediates_dir = temp_dir,
                           quiet = TRUE)
         },
         stop("Unsupported format. Use 'md', 'html', or 'pdf'.")
  )
  
  cli::cli_alert_success("Decision tree exported to {output_path}")
  invisible(output_path)
} 