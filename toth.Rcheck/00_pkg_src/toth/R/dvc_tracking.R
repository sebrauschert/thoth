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
#'   write_csv("data/processed/mydata.csv") |>
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
#'
#' @param x A data frame to write
#' @param file Path to write to
#' @param message Optional DVC commit message
#' @param ... Additional arguments passed to readr::write_csv
#' @return The input data frame (invisibly) to allow for further piping
#' @export
#'
#' @examples
#' \dontrun{
#' data |> write_csv_dvc("data/processed/mydata.csv", "Updated data")
#' }
write_csv_dvc <- function(x, file, message = NULL, ...) {
  readr::write_csv(x, file, ...)
  dvc_track(file, message)
  invisible(x)
}

#' Write RDS with DVC tracking
#'
#' @description
#' A wrapper around saveRDS that automatically tracks the output file with DVC
#'
#' @param object Object to save
#' @param file Path to write to
#' @param message Optional DVC commit message
#' @param ... Additional arguments passed to saveRDS
#' @return The input object (invisibly) to allow for further piping
#' @export
#'
#' @examples
#' \dontrun{
#' model |> write_rds_dvc("models/model.rds", "Updated model")
#' }
write_rds_dvc <- function(object, file, message = NULL, ...) {
  saveRDS(object, file, ...)
  dvc_track(file, message)
  invisible(object)
} 