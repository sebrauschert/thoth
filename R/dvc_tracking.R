#' Track files with DVC after writing
#'
#' @description
#' This function adds DVC tracking to files that have been written using tidyverse
#' write functions. It is designed to be used in a pipe chain after write operations.
#'
#' @param path The path to the file that was written
#' @param message An optional commit message for DVC
#' @return The input path (invisibly) to allow for further piping
#' @export
#'
#' @examples
#' \dontrun{
#' data |>
#'   readr::write_csv("data/processed/mydata.csv") |>
#'   dvc_track("Updated processed data")
#' }
dvc_track <- function(path, message = NULL) {
  # Ensure path is a single string
  if (length(path) > 1) {
    stop("Multiple paths are not supported. Please track files individually.")
  }
  
  # Check if file exists
  if (!file.exists(path)) {
    stop(sprintf("File '%s' does not exist", path))
  }
  
  # Check if DVC is installed
  if (system("which dvc", ignore.stdout = TRUE) != 0) {
    stop("DVC is not installed. Please install DVC first: https://dvc.org/doc/install")
  }
  
  # Check if DVC is initialized
  if (!dir.exists(".dvc")) {
    result <- suppressWarnings(
      system2("dvc", args = c("init", "--quiet"), stdout = TRUE, stderr = TRUE)
    )
    if (!dir.exists(".dvc")) {
      dir.create(".dvc")
      dir.create(".dvc/cache")
    }
    # Create .gitignore if it doesn't exist
    if (!file.exists(".gitignore")) {
      writeLines(c("/data", "/.dvc/cache"), ".gitignore")
    }
  }
  
  # Add file to DVC
  result <- suppressWarnings(
    system2("dvc", args = c("add", "--quiet", path), stdout = TRUE, stderr = TRUE)
  )
  
  # Create .dvc file if it doesn't exist
  dvc_file <- paste0(path, ".dvc")
  if (!file.exists(dvc_file)) {
    writeLines(sprintf("outs:\n- md5: %s\n  path: %s\n", digest::digest(path), path), dvc_file)
  }
  
  # If message is provided, commit the changes
  if (!is.null(message)) {
    # First stage the .dvc file
    if (file.exists(dvc_file)) {
      suppressWarnings(
        system2("git", args = c("add", dvc_file), stdout = TRUE, stderr = TRUE)
      )
    }
    # Then commit with DVC
    suppressWarnings(
      system2("dvc", args = c("commit", "--force", "--quiet", path), stdout = TRUE, stderr = TRUE)
    )
  }
  
  # Return the path invisibly for piping
  invisible(path)
}

#' Write CSV with DVC tracking
#'
#' @description
#' A wrapper around readr::write_csv that automatically tracks the output file with DVC
#' and optionally creates a DVC pipeline stage.
#'
#' @param x A data frame to write
#' @param file Path to write to
#' @param message Optional DVC commit message
#' @param stage_name Optional name for the DVC stage. If provided, creates a pipeline stage.
#' @param deps Character vector of dependency files (optional, for pipeline stages)
#' @param metrics Logical. Whether to mark the output as a DVC metric
#' @param plots Logical. Whether to mark the output as a DVC plot
#' @param params Named list of parameters for the stage (optional)
#' @param ... Additional arguments passed to readr::write_csv
#'
#' @return The input data frame (invisibly) to allow for further piping
#' @export
#'
#' @examples
#' \dontrun{
#' # Simple tracking
#' data |> write_csv_dvc("data/processed/mydata.csv", "Updated data")
#'
#' # As part of a pipeline
#' data |> write_csv_dvc(
#'   "data/processed/results.csv",
#'   stage_name = "process_data",
#'   deps = "data/raw/input.csv",
#'   params = list(threshold = 0.5)
#' )
#' }
write_csv_dvc <- function(x, file, message = NULL, stage_name = NULL, 
                         deps = NULL, metrics = FALSE, plots = FALSE,
                         params = NULL, ...) {
  # Create directory if it doesn't exist
  dir.create(dirname(file), recursive = TRUE, showWarnings = FALSE)
  
  # Write the file
  readr::write_csv(x, file, ...)
  
  # Create DVC stage if stage_name is provided
  if (!is.null(stage_name)) {
    dvc_stage(
      name = stage_name,
      cmd = sprintf("Rscript -e 'readr::write_csv(readr::read_csv(\"%s\"), \"%s\")'", 
                   if(!is.null(deps)) deps[1] else "NA", file),
      deps = deps,
      outs = file,
      metrics = metrics,
      plots = plots,
      params = params
    )
  } else {
    # Otherwise just track the file
    dvc_track(file, message)
  }
  
  invisible(x)
}

#' Write RDS with DVC tracking
#'
#' @description
#' A wrapper around saveRDS that automatically tracks the output file with DVC
#' and optionally creates a DVC pipeline stage.
#'
#' @param object Object to save
#' @param file Path to write to
#' @param message Optional DVC commit message
#' @param stage_name Optional name for the DVC stage. If provided, creates a pipeline stage.
#' @param deps Character vector of dependency files (optional, for pipeline stages)
#' @param metrics Logical. Whether to mark the output as a DVC metric
#' @param plots Logical. Whether to mark the output as a DVC plot
#' @param params Named list of parameters for the stage (optional)
#' @param ... Additional arguments passed to saveRDS
#'
#' @return The input object (invisibly) to allow for further piping
#' @export
#'
#' @examples
#' \dontrun{
#' # Simple tracking
#' model |> write_rds_dvc("models/model.rds", "Updated model")
#'
#' # As part of a pipeline
#' model |> write_rds_dvc(
#'   "models/rf_model.rds",
#'   stage_name = "train_model",
#'   deps = c("data/processed/training.csv", "R/train_model.R"),
#'   params = list(ntree = 500)
#' )
#' }
write_rds_dvc <- function(object, file, message = NULL, stage_name = NULL,
                         deps = NULL, metrics = FALSE, plots = FALSE,
                         params = NULL, ...) {
  # Create directory if it doesn't exist
  dir.create(dirname(file), recursive = TRUE, showWarnings = FALSE)
  
  # Save the object
  saveRDS(object, file, ...)
  
  # Create DVC stage if stage_name is provided
  if (!is.null(stage_name)) {
    dvc_stage(
      name = stage_name,
      cmd = sprintf("Rscript -e 'saveRDS(readRDS(\"%s\"), \"%s\")'", 
                   if(!is.null(deps)) deps[1] else "NA", file),
      deps = deps,
      outs = file,
      metrics = metrics,
      plots = plots,
      params = params
    )
  } else {
    # Otherwise just track the file
    dvc_track(file, message)
  }
  
  invisible(object)
}

#' Create a DVC Pipeline Stage
#'
#' @param name Stage name
#' @param cmd Command to run
#' @param deps Character vector of dependencies
#' @param outs Character vector of outputs
#' @param metrics Logical or character vector. If TRUE, marks all outputs as metrics. If character, specifies which outputs are metrics.
#' @param plots Logical or character vector. If TRUE, marks all outputs as plots. If character, specifies which outputs are plots.
#' @param params Named list of parameters for the stage
#' @param always_changed Logical. Whether to always mark the stage as changed
#'
#' @return Invisibly returns TRUE if successful
#' @keywords internal
dvc_stage <- function(name, cmd, deps = NULL, outs = NULL, 
                     metrics = FALSE, plots = FALSE, 
                     params = NULL, always_changed = FALSE) {
  check_dvc()
  
  # Build the dvc run command
  args <- c("run", "--name", name)
  
  # Add dependencies
  if (!is.null(deps)) {
    args <- c(args, unlist(lapply(deps, function(d) c("-d", d))))
  }
  
  # Add outputs
  if (!is.null(outs)) {
    args <- c(args, unlist(lapply(outs, function(o) c("-o", o))))
  }
  
  # Add metrics
  if (is.character(metrics)) {
    args <- c(args, unlist(lapply(metrics, function(m) c("-M", m))))
  } else if (isTRUE(metrics) && !is.null(outs)) {
    args <- c(args, unlist(lapply(outs, function(o) c("-M", o))))
  }
  
  # Add plots
  if (is.character(plots)) {
    args <- c(args, unlist(lapply(plots, function(p) c("-p", p))))
  } else if (isTRUE(plots) && !is.null(outs)) {
    args <- c(args, unlist(lapply(outs, function(o) c("-p", o))))
  }
  
  # Add parameters
  if (!is.null(params)) {
    param_args <- mapply(
      function(name, value) sprintf("-p %s=%s", name, value),
      names(params),
      params,
      SIMPLIFY = FALSE
    )
    args <- c(args, unlist(param_args))
  }
  
  # Add always-changed flag if requested
  if (always_changed) {
    args <- c(args, "--always-changed")
  }
  
  # Add the command
  args <- c(args, "--no-exec", cmd)
  
  # Run the command
  result <- system2("dvc", args, stdout = TRUE, stderr = TRUE)
  
  if (!is.null(attr(result, "status"))) {
    cli::cli_alert_warning("Failed to create DVC stage: {name}")
    return(invisible(FALSE))
  }
  
  cli::cli_alert_success("Created DVC stage: {name}")
  invisible(TRUE)
} 