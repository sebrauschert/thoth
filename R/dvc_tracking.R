#' Track files with DVC after writing
#'
#' @description
#' This function adds DVC tracking to files that have been written using tidyverse
#' write functions. It is designed to be used in a pipe chain after write operations.
#'
#' @param path The path to the file that was written
#' @param message An optional commit message for DVC
#' @param push Logical. Whether to push changes to Git remote (default: FALSE)
#' @return The input path (invisibly) to allow for further piping
#' @export
#' @importFrom cli cli_alert_success cli_alert_info cli_alert_warning cli_alert_danger
#'
#' @examples
#' \dontrun{
#' data |>
#'   readr::write_csv("data/processed/mydata.csv") |>
#'   dvc_track("Updated processed data", push = TRUE)
#' }
dvc_track <- function(path, message = NULL, push = FALSE) {
  # Check if file exists
  if (!file.exists(path)) {
    cli::cli_abort(glue::glue("File {fs::path(path)} does not exist"))
  }
  
  # Check if multiple paths were provided
  if (length(path) > 1) {
    cli::cli_abort("Multiple paths are not supported")
  }
  
  # Check DVC availability
  has_dvc <- check_command("dvc", min_version = "2.0.0")
  
  if (!has_dvc) {
    cli::cli_alert_warning("DVC is not installed or not found in PATH")
    cli::cli_alert_info("Creating mock .dvc file instead")
    
    # Create mock .dvc file
    dvc_file <- fs::path(paste0(path, ".dvc"))
    writeLines(sprintf("outs:\n- md5: %s\n  path: %s\n", 
                      digest::digest(path), 
                      path), 
              dvc_file)
    
    cli::cli_alert_success(glue::glue("Created mock {fs::path(dvc_file)}"))
    return(invisible(path))
  }
  
  # Add file to DVC
  result <- system2("dvc", 
                    c("add", "-f", "-q", path), # Added -q for quiet mode
                    stdout = TRUE, 
                    stderr = TRUE)
  
  # Check for errors
  if (!is.null(attr(result, "status")) && attr(result, "status") != 0) {
    cli::cli_abort(format_cli_error("dvc add", result, 
                                  attr(result, "status"), 
                                  "Failed to add file to DVC tracking"))
  }
  
  # Success message for DVC tracking
  cli::cli_alert_success("Successfully added {fs::path(path)} to DVC tracking")
  
  # Add .dvc file to Git with force flag
  dvc_file <- fs::path(paste0(path, ".dvc"))
  if (file.exists(dvc_file)) {
    git_add(dvc_file, force = TRUE)
    
    # Commit if message provided
    if (!is.null(message)) {
      git_commit(message)
      
      # Push if requested
      if (push) {
        git_push()
      }
    }
  }
  
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
#' @param push Logical, whether to push changes to Git remote (default: FALSE)
#' @return The input data frame (invisibly) to allow for further piping
#' @export
#'
#' @examples
#' \dontrun{
#' # Simple tracking
#' data |> write_csv_dvc(
#'   "data/processed/results.csv",
#'   message = "Add processed results",
#'   push = TRUE
#' )
#'
#' # As part of a pipeline
#' data |> write_csv_dvc(
#'   "data/processed/features.csv",
#'   message = "Add feature matrix",
#'   stage_name = "feature_engineering",
#'   deps = "data/raw/input.csv",
#'   params = list(n_components = 10),
#'   push = TRUE
#' )
#' }
write_csv_dvc <- function(x, path, message, stage_name = NULL,
                         deps = NULL, params = NULL, metrics = FALSE,
                         push = FALSE) {
  
  dir_path <- dirname(path)
  if (!dir.exists(dir_path)) {
    dir.create(dir_path, recursive = TRUE, showWarnings = FALSE)
  }
  
  # Handle matrix columns and clean column names
  x <- as.data.frame(lapply(x, function(col) {
    if (is.matrix(col)) {
      # Extract the first column if it's a matrix
      col[,1]
    } else if (is.list(col)) {
      # Convert list to character
      as.character(col)
    } else {
      col
    }
  }))
  
  # Clean column names by removing [,1]
  names(x) <- gsub("\\[,1\\]$", "", names(x))
  
  # Write the CSV file
  readr::write_csv(x, path)
  
  # Check if DVC is installed - platform independent check
  dvc_installed <- tryCatch({
    if (.Platform$OS.type == "windows") {
      # Windows check
      result <- suppressWarnings(system("where dvc", ignore.stdout = TRUE))
    } else {
      # Unix-like check
      result <- suppressWarnings(system("which dvc", ignore.stdout = TRUE))
    }
    result == 0
  }, error = function(e) {
    FALSE
  })
  
  if (!dvc_installed) {
    warning("DVC is not installed. Please install DVC first: https://dvc.org/doc/install")
    # Create a mock .dvc file to allow the workflow to continue
    dvc_file <- paste0(path, ".dvc")
    if (!file.exists(dvc_file)) {
      writeLines(sprintf("outs:\n- md5: %s\n  path: %s\n", digest::digest(path), path), dvc_file)
    }
    return(invisible(x))
  }
  
  # If no stage name provided, just track with dvc add
  if (is.null(stage_name)) {
    # Track the file with DVC first
    dvc_result <- system2("dvc", c("add", "-f", path), stdout = TRUE, stderr = TRUE)
    
    if (!is.null(attr(dvc_result, "status")) && attr(dvc_result, "status") != 0) {
      cli::cli_alert_warning("Failed to add file to DVC tracking")
      cli::cli_alert_info("DVC output: {paste(dvc_result, collapse = '\n')}")
      return(invisible(x))
    }
    
    # Collect all files that need to be added to Git
    files_to_add <- character(0)
    
    # Add DVC files to the list
    dvc_files <- c(
      paste0(path, ".dvc"),
      ".dvc/config",
      ".dvc/config.local",
      ".dvc/.gitignore",
      "dvc.yaml",
      "dvc.lock"
    )
    
    # Add each DVC file that exists
    for (file in dvc_files) {
      if (file.exists(file)) {
        files_to_add <- c(files_to_add, file)
      }
    }
    
    # Add all files at once
    if (length(files_to_add) > 0) {
      git_add(files_to_add, force = TRUE)
    }
    
    # Commit if message provided
    if (!is.null(message)) {
      git_commit(message)
      
      # Push if requested
      if (push) {
        git_push()
      }
    }
    
    cli::cli_alert_success("Successfully tracked {path} with DVC")
    return(invisible(x))
  }
  
  # Create R/pipeline directory if it doesn't exist
  pipeline_dir <- "R/pipeline"
  if (!dir.exists(pipeline_dir)) {
    dir.create(pipeline_dir, recursive = TRUE, showWarnings = FALSE)
  }
  
  # Create a permanent R script for this stage
  script_path <- file.path(pipeline_dir, paste0(stage_name, ".R"))
  
  # Write the R script with proper documentation and error handling
  script_content <- c(
    "#!/usr/bin/env Rscript",
    "",
    sprintf("# DVC stage: %s", stage_name),
    sprintf("# Created: %s", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
    "",
    "# Load required packages",
    "library(readr)",
    "library(dplyr)",
    "",
    "# Read input data if there are dependencies",
    if (!is.null(deps)) {
      c("# Read dependencies",
        sprintf('input_data <- read_csv("%s")', deps[1]))
    },
    "",
    "# Define the data to write",
    "x <- get('x', envir = parent.frame())",
    "",
    "# Write the CSV file",
    sprintf('write_csv(x, "%s")', path),
    "",
    "# Exit successfully",
    "quit(save = 'no', status = 0)"
  )
  
  # Write the script
  writeLines(script_content, script_path)
  
  # Make the script executable
  if (.Platform$OS.type != "windows") {
    system2("chmod", c("+x", script_path))
  }
  
  # Build DVC command arguments
  dvc_args <- c("stage", "add", "-n", stage_name)
  
  if (!is.null(deps)) {
    dvc_args <- c(dvc_args, unlist(lapply(deps, function(d) c("-d", d))))
  }
  
  # Add script as a dependency
  dvc_args <- c(dvc_args, "-d", script_path)
  
  # File can't be both output and metrics
  if (metrics) {
    dvc_args <- c(dvc_args, "-M", path)
  } else {
    dvc_args <- c(dvc_args, "-o", path)
  }
  
  # Add parameters with proper formatting
  if (!is.null(params)) {
    # Create params.yaml if it doesn't exist
    if (!file.exists("params.yaml")) {
      writeLines("", "params.yaml")
    }
    
    # Update params.yaml with new parameters
    params_yaml <- if (file.exists("params.yaml")) {
      yaml::read_yaml("params.yaml")
    } else {
      list()
    }
    
    # Add stage-specific parameters
    params_yaml[[stage_name]] <- params
    yaml::write_yaml(params_yaml, "params.yaml")
    
    # Add params.yaml as a dependency
    dvc_args <- c(dvc_args, "-d", "params.yaml")
    
    # Add parameter references
    param_args <- mapply(
      function(name, value) {
        c("-p", sprintf("%s.%s", stage_name, name))
      },
      names(params),
      params,
      SIMPLIFY = FALSE
    )
    dvc_args <- c(dvc_args, unlist(param_args))
  }
  
  # Add the command with proper quoting
  dvc_args <- c(dvc_args, shQuote(sprintf("Rscript %s", script_path)))
  
  # Execute DVC command
  tryCatch({
    # First, ensure the file is not tracked by Git if it exists
    # Only try to remove if git status shows it's tracked
    status_output <- git_status()
    if (length(grep(path, status_output, value = TRUE)) > 0) {
      system2("git", c("rm", "-f", "--cached", path), stdout = TRUE, stderr = TRUE)
    }
    
    # Create DVC stage
    dvc_result <- system2("dvc", dvc_args, stdout = TRUE, stderr = TRUE)
    
    if (!is.null(attr(dvc_result, "status")) && attr(dvc_result, "status") != 0) {
      cli::cli_alert_warning("Failed to create DVC stage: {stage_name}")
      cli::cli_alert_info("DVC output: {paste(dvc_result, collapse = '\n')}")
      return(invisible(x))
    }
    
    # Collect all files that need to be added to Git
    files_to_add <- character(0)
    
    # Add DVC files and R script to the list
    dvc_files <- c(
      "dvc.yaml",
      "dvc.lock",
      ".dvc/config",
      ".dvc/config.local",
      ".dvc/.gitignore",
      "params.yaml",
      script_path
    )
    
    # Add existing files to the list
    for (file in dvc_files) {
      if (file.exists(file)) {
        files_to_add <- c(files_to_add, file)
      }
    }
    
    # Check for any other untracked or modified files
    status_output <- git_status()
    if (length(status_output) > 0) {
      # Get untracked files
      untracked <- grep("^\\?\\? ", status_output, value = TRUE)
      if (length(untracked) > 0) {
        untracked_files <- sub("^\\?\\? ", "", untracked)
        files_to_add <- c(files_to_add, untracked_files)
      }
      
      # Get modified files
      modified <- grep("^ M ", status_output, value = TRUE)
      if (length(modified) > 0) {
        modified_files <- sub("^ M ", "", modified)
        files_to_add <- c(files_to_add, modified_files)
      }
    }
    
    # Add all files at once
    if (length(files_to_add) > 0) {
      git_add(files_to_add, force = TRUE)
    }
    
    # Commit if message provided
    if (!is.null(message)) {
      git_commit(message)
      
      # Push if requested
      if (push) {
        git_push()
      }
    }
    
    cli::cli_alert_success("Successfully created DVC stage: {stage_name}")
  }, error = function(e) {
    cli::cli_alert_danger("Error creating DVC stage: {conditionMessage(e)}")
  })
  
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
#' @param push Logical. Whether to push changes to Git remote (default: FALSE)
#' @param ... Additional arguments passed to saveRDS
#'
#' @return The input object (invisibly) to allow for further piping
#' @export
#'
#' @examples
#' \dontrun{
#' # Simple tracking
#' model |> write_rds_dvc(
#'   "models/model.rds",
#'   message = "Updated model",
#'   push = TRUE
#' )
#'
#' # As part of a pipeline
#' model |> write_rds_dvc(
#'   "models/rf_model.rds",
#'   message = "Save trained random forest model",
#'   stage_name = "train_model",
#'   deps = c("data/processed/training.csv", "R/train_model.R"),
#'   params = list(ntree = 500),
#'   push = TRUE
#' )
#' }
write_rds_dvc <- function(object, file, message = NULL, stage_name = NULL,
                         deps = NULL, metrics = FALSE, plots = FALSE,
                         params = NULL, push = FALSE, ...) {
  # Create directory if it doesn't exist
  dir_path <- dirname(file)
  if (!dir.exists(dir_path)) {
    dir.create(dir_path, recursive = TRUE, showWarnings = FALSE)
  }
  
  # Handle matrix and list columns if the object is a data frame
  if (is.data.frame(object)) {
    object <- as.data.frame(lapply(object, function(col) {
      if (is.matrix(col)) {
        # Extract the first column if it's a matrix
        col[,1]
      } else if (is.list(col)) {
        # Convert list to character
        as.character(col)
      } else {
        col
      }
    }))
    
    # Clean column names by removing [,1]
    names(object) <- gsub("\\[,1\\]$", "", names(object))
  }
  
  # Save the object
  saveRDS(object, file, ...)
  
  # Check if DVC is installed - platform independent check
  dvc_installed <- tryCatch({
    if (.Platform$OS.type == "windows") {
      # Windows check
      result <- suppressWarnings(system("where dvc", ignore.stdout = TRUE))
    } else {
      # Unix-like check
      result <- suppressWarnings(system("which dvc", ignore.stdout = TRUE))
    }
    result == 0
  }, error = function(e) {
    FALSE
  })
  
  if (!dvc_installed) {
    warning("DVC is not installed. Please install DVC first: https://dvc.org/doc/install")
    # Create a mock .dvc file to allow the workflow to continue
    dvc_file <- paste0(file, ".dvc")
    if (!file.exists(dvc_file)) {
      writeLines(sprintf("outs:\n- md5: %s\n  path: %s\n", digest::digest(file), file), dvc_file)
    }
    return(invisible(object))
  }
  
  # If no stage name provided, just track with dvc add
  if (is.null(stage_name)) {
    # Track the file with DVC first
    dvc_result <- system2("dvc", c("add", "-f", file), stdout = TRUE, stderr = TRUE)
    
    if (!is.null(attr(dvc_result, "status")) && attr(dvc_result, "status") != 0) {
      cli::cli_alert_warning("Failed to add file to DVC tracking")
      cli::cli_alert_info("DVC output: {paste(dvc_result, collapse = '\n')}")
      return(invisible(object))
    }
    
    # Collect all files that need to be added to Git
    files_to_add <- character(0)
    
    # Add DVC files to the list
    dvc_files <- c(
      paste0(file, ".dvc"),
      ".dvc/config",
      ".dvc/config.local",
      ".dvc/.gitignore",
      "dvc.yaml",
      "dvc.lock"
    )
    
    # Add each DVC file that exists
    for (dvc_file in dvc_files) {
      if (file.exists(dvc_file)) {
        files_to_add <- c(files_to_add, dvc_file)
      }
    }
    
    # Check git status and add any remaining untracked or modified files
    status_output <- git_status()
    if (length(status_output) > 0) {
      # Get untracked files
      untracked <- grep("^\\?\\? ", status_output, value = TRUE)
      if (length(untracked) > 0) {
        untracked_files <- sub("^\\?\\? ", "", untracked)
        files_to_add <- c(files_to_add, untracked_files)
      }
      
      # Get modified files
      modified <- grep("^ M ", status_output, value = TRUE)
      if (length(modified) > 0) {
        modified_files <- sub("^ M ", "", modified)
        files_to_add <- c(files_to_add, modified_files)
      }
    }
    
    # Add all files at once
    if (length(files_to_add) > 0) {
      git_add(files_to_add, force = TRUE)
    }
    
    # Commit if message provided
    if (!is.null(message)) {
      git_commit(message)
      
      # Push if requested
      if (push) {
        git_push()
      }
    }
    
    cli::cli_alert_success("Successfully tracked {file} with DVC")
    return(invisible(object))
  }
  
  # Create R/pipeline directory if it doesn't exist
  pipeline_dir <- "R/pipeline"
  if (!dir.exists(pipeline_dir)) {
    dir.create(pipeline_dir, recursive = TRUE, showWarnings = FALSE)
  }
  
  # Create a permanent R script for this stage
  script_path <- file.path(pipeline_dir, paste0(stage_name, ".R"))
  
  # Write the R script with proper documentation and error handling
  script_content <- c(
    "#!/usr/bin/env Rscript",
    "",
    sprintf("# DVC stage: %s", stage_name),
    sprintf("# Created: %s", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
    "",
    "# Load required packages",
    "",
    "# Read input data if there are dependencies",
    if (!is.null(deps)) {
      c("# Read dependencies",
        sprintf('input_data <- readRDS("%s")', deps[1]))
    },
    "",
    "# Define the object to save",
    "object <- get('object', envir = parent.frame())",
    "",
    "# Save the object",
    sprintf('saveRDS(object, "%s")', file),
    "",
    "# Exit successfully",
    "quit(save = 'no', status = 0)"
  )
  
  # Write the script
  writeLines(script_content, script_path)
  
  # Make the script executable
  if (.Platform$OS.type != "windows") {
    system2("chmod", c("+x", script_path))
  }
  
  # Build DVC command arguments
  dvc_args <- c("stage", "add", "-n", stage_name)
  
  if (!is.null(deps)) {
    dvc_args <- c(dvc_args, unlist(lapply(deps, function(d) c("-d", d))))
  }
  
  # Add script as a dependency
  dvc_args <- c(dvc_args, "-d", script_path)
  
  # Handle outputs based on metrics and plots flags
  if (metrics) {
    dvc_args <- c(dvc_args, "-M", file)
  } else if (plots) {
    dvc_args <- c(dvc_args, "--plots", file)
  } else {
    dvc_args <- c(dvc_args, "-o", file)
  }
  
  # Add parameters with proper formatting
  if (!is.null(params)) {
    # Create params.yaml if it doesn't exist
    if (!file.exists("params.yaml")) {
      writeLines("", "params.yaml")
    }
    
    # Update params.yaml with new parameters
    params_yaml <- if (file.exists("params.yaml")) {
      yaml::read_yaml("params.yaml")
    } else {
      list()
    }
    
    # Add stage-specific parameters
    params_yaml[[stage_name]] <- params
    yaml::write_yaml(params_yaml, "params.yaml")
    
    # Add params.yaml as a dependency
    dvc_args <- c(dvc_args, "-d", "params.yaml")
    
    # Add parameter references
    param_args <- mapply(
      function(name, value) {
        c("-p", sprintf("%s.%s", stage_name, name))
      },
      names(params),
      params,
      SIMPLIFY = FALSE
    )
    dvc_args <- c(dvc_args, unlist(param_args))
  }
  
  # Add the command with proper quoting
  dvc_args <- c(dvc_args, shQuote(sprintf("Rscript %s", script_path)))
  
  # Execute DVC command
  tryCatch({
    # First, ensure the file is not tracked by Git if it exists
    # Only try to remove if git status shows it's tracked
    status_output <- git_status()
    if (length(grep(file, status_output, value = TRUE)) > 0) {
      system2("git", c("rm", "-f", "--cached", file), stdout = TRUE, stderr = TRUE)
    }
    
    # Create DVC stage
    dvc_result <- system2("dvc", dvc_args, stdout = TRUE, stderr = TRUE)
    
    if (!is.null(attr(dvc_result, "status")) && attr(dvc_result, "status") != 0) {
      cli::cli_alert_warning("Failed to create DVC stage: {stage_name}")
      cli::cli_alert_info("DVC output: {paste(dvc_result, collapse = '\n')}")
      return(invisible(object))
    }
    
    # Collect all files that need to be added to Git
    files_to_add <- character(0)
    
    # Add DVC files and R script to the list
    dvc_files <- c(
      "dvc.yaml",
      "dvc.lock",
      ".dvc/config",
      ".dvc/config.local",
      ".dvc/.gitignore",
      "params.yaml",
      script_path
    )
    
    # Add existing files to the list
    for (file in dvc_files) {
      if (file.exists(file)) {
        files_to_add <- c(files_to_add, file)
      }
    }
    
    # Check for any other untracked or modified files
    status_output <- git_status()
    if (length(status_output) > 0) {
      # Get untracked files
      untracked <- grep("^\\?\\? ", status_output, value = TRUE)
      if (length(untracked) > 0) {
        untracked_files <- sub("^\\?\\? ", "", untracked)
        files_to_add <- c(files_to_add, untracked_files)
      }
      
      # Get modified files
      modified <- grep("^ M ", status_output, value = TRUE)
      if (length(modified) > 0) {
        modified_files <- sub("^ M ", "", modified)
        files_to_add <- c(files_to_add, modified_files)
      }
    }
    
    # Add all files at once
    if (length(files_to_add) > 0) {
      git_add(files_to_add, force = TRUE)
    }
    
    # Commit if message provided
    if (!is.null(message)) {
      git_commit(message)
      
      # Push if requested
      if (push) {
        git_push()
      }
    }
    
    cli::cli_alert_success("Successfully created DVC stage: {stage_name}")
  }, error = function(e) {
    cli::cli_alert_danger("Error creating DVC stage: {conditionMessage(e)}")
  })
  
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
    args <- c(args, unlist(lapply(plots, function(p) c("--plots", p))))
  } else if (isTRUE(plots) && !is.null(outs)) {
    args <- c(args, unlist(lapply(outs, function(o) c("--plots", o))))
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
  
  # Add DVC files to Git using our git functions
  git_add(c("dvc.yaml", "dvc.lock"), force = TRUE)
  
  cli::cli_alert_success("Created DVC stage: {name}")
  invisible(TRUE)
} 