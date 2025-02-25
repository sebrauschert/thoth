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
  
  # Check if the command failed and emit a message
  if (is.character(result) && length(result) > 0) {
    message(sprintf("Failed to add %s to DVC tracking", path))
  }
  
  # Create .dvc file if it doesn't exist
  dvc_file <- paste0(path, ".dvc")
  if (!file.exists(dvc_file)) {
    writeLines(sprintf("outs:\n- md5: %s\n  path: %s\n", digest::digest(path), path), dvc_file)
  }
  
  # If message is provided, commit the changes
  if (!is.null(message)) {
    # First stage the .dvc file
    if (file.exists(dvc_file)) {
      git_result <- suppressWarnings(
        system2("git", args = c("add", dvc_file), stdout = TRUE, stderr = TRUE)
      )
      if (is.character(git_result) && length(git_result) > 0) {
        message("Failed to add files to Git")
      }
    }
    # Then commit with DVC
    dvc_commit_result <- suppressWarnings(
      system2("dvc", args = c("commit", "--force", "--quiet", path), stdout = TRUE, stderr = TRUE)
    )
    if (is.character(dvc_commit_result) && length(dvc_commit_result) > 0) {
      message("Failed to commit changes to Git")
    }
  }
  
  # Return the path invisibly for piping
  invisible(path)
}

#' Write a CSV file and track it with DVC
#'
#' @param x A data frame to write to CSV
#' @param path Path to save the CSV file
#' @param message Git commit message
#' @param stage_name Optional DVC stage name
#' @param deps Optional vector of dependency files
#' @param params Optional list of parameters
#' @param metrics Logical, whether to track as DVC metrics (default: FALSE)
#' @return The input data frame (invisibly) to allow for further piping
#' @export
write_csv_dvc <- function(x, path, message, stage_name = NULL,
                         deps = NULL, params = NULL, metrics = FALSE) {
  # Create directory if it doesn't exist
  dir_path <- dirname(path)
  if (!dir.exists(dir_path)) {
    dir.create(dir_path, recursive = TRUE, showWarnings = FALSE)
  }
  
  # Write the CSV file
  readr::write_csv(x, path)
  
  # If no stage name provided, just track with dvc add
  if (is.null(stage_name)) {
    tryCatch({
      dvc_add(path)
      git_add(path)
      git_commit(message)
    }, error = function(e) {
      cli::cli_abort(
        c("Failed to track file with DVC",
          "i" = "Error message: {conditionMessage(e)}"),
        call = NULL
      )
    })
    return(invisible(x))  # Return input data for piping
  }
  
  # Prepare DVC stage command
  temp_script <- tempfile(pattern = "dvc_stage_", fileext = ".R")
  writeLines(sprintf('readr::write_csv(x, "%s")', path), temp_script)
  
  # Build DVC command arguments
  dvc_args <- c("stage", "add", "-n", stage_name)
  
  if (!is.null(deps)) {
    dvc_args <- c(dvc_args, "-d", deps)
  }
  
  # File can't be both output and metrics
  if (metrics) {
    dvc_args <- c(dvc_args, "-M", path)
  } else {
    dvc_args <- c(dvc_args, "-o", path)
  }
  
  if (!is.null(params)) {
    param_args <- unlist(Map(function(name, value) {
      c("-p", sprintf("%s=%s", name, as.character(value)))
    }, names(params), params))
    dvc_args <- c(dvc_args, param_args)
  }
  
  dvc_args <- c(dvc_args, sprintf("'Rscript %s'", temp_script))
  
  # Execute DVC command with better error handling
  result <- tryCatch({
    system2("dvc", dvc_args, stdout = TRUE, stderr = TRUE)
    git_add(c(path, "dvc.yaml", "dvc.lock"))
    git_commit(message)
    cli::cli_alert_success("Successfully created DVC stage: {stage_name}")
  }, error = function(e) {
    unlink(temp_script)
    cli::cli_abort(
      c("Failed to create DVC stage: {stage_name}",
        "i" = "DVC output: {paste(result, collapse = '\n')}"),
      call = NULL
    )
  }, finally = {
    unlink(temp_script)
  })
  
  invisible(x)  # Return input data for piping
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
  
  invisible(object)  # Return input object for piping
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
  
  # Add parameters with proper formatting
  if (!is.null(params)) {
    param_args <- mapply(
      function(name, value) {
        # Format the parameter value based on its type
        formatted_value <- if (is.character(value)) {
          shQuote(value)
        } else if (is.numeric(value)) {
          as.character(value)
        } else if (is.logical(value)) {
          tolower(as.character(value))
        } else {
          as.character(value)
        }
        c("-p", paste(name, formatted_value, sep = "="))
      },
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
  
  # Add the command with proper quoting
  args <- c(args, "--no-exec", shQuote(cmd))
  
  # Run the command
  result <- tryCatch({
    system2("dvc", args, stdout = TRUE, stderr = TRUE)
  }, error = function(e) {
    cli::cli_alert_warning("Error executing DVC command: {e$message}")
    return(NULL)
  })
  
  if (!is.null(attr(result, "status"))) {
    cli::cli_alert_warning("Failed to create DVC stage: {name}")
    cli::cli_alert_info("DVC output: {paste(result, collapse = '\n')}")
    return(invisible(FALSE))
  }
  
  cli::cli_alert_success("Created DVC stage: {name}")
  invisible(TRUE)
} 