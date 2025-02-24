#' Version Control Functions
#' @name version_control
#' @description Functions for interacting with DVC and Git from R
#'
#' @importFrom cli cli_alert_success cli_alert_info cli_alert_warning
NULL

#' Track Files with DVC
#'
#' @param path Character vector of file paths to track
#' @param message Optional commit message for DVC
#' @param recursive Logical. Whether to recursively add directories. Default is FALSE.
#' @param git_add Logical. Whether to automatically add the .dvc files to git. Default is TRUE.
#'
#' @return Invisibly returns the tracked paths
#' @export
dvc_add <- function(path, message = NULL, recursive = FALSE, git_add = TRUE) {
  # Ensure DVC is installed
  check_dvc()
  
  # Handle multiple paths
  paths <- normalizePath(path, mustWork = TRUE)
  
  for (p in paths) {
    args <- c("add", if(recursive) "--recursive" else NULL, p)
    result <- system2("dvc", args, stdout = TRUE, stderr = TRUE)
    
    if (!is.null(attr(result, "status"))) {
      cli::cli_alert_warning("Failed to add {p} to DVC tracking")
      next
    }
    
    dvc_file <- paste0(p, ".dvc")
    if (git_add && file.exists(dvc_file)) {
      git_add(dvc_file)
    }
    
    cli::cli_alert_success("Added {p} to DVC tracking")
  }
  
  if (!is.null(message)) {
    dvc_commit(paths, message)
  }
  
  invisible(paths)
}

#' Commit Changes to DVC
#'
#' @param path Character vector of file paths to commit
#' @param message Commit message
#'
#' @return Invisibly returns TRUE if successful
#' @export
dvc_commit <- function(path, message) {
  check_dvc()
  
  args <- c("commit", "--force", "--quiet", path)
  result <- system2("dvc", args, stdout = TRUE, stderr = TRUE)
  
  if (!is.null(attr(result, "status"))) {
    cli::cli_alert_warning("Failed to commit changes to DVC")
    return(invisible(FALSE))
  }
  
  cli::cli_alert_success("Committed changes to DVC")
  invisible(TRUE)
}

#' Pull Data from DVC Remote
#'
#' @param path Optional character vector of specific paths to pull
#' @param remote Optional name of the remote to pull from
#'
#' @return Invisibly returns TRUE if successful
#' @export
dvc_pull <- function(path = NULL, remote = NULL) {
  check_dvc()
  
  args <- c("pull", 
            if(!is.null(remote)) c("--remote", remote) else NULL,
            path)
  
  result <- system2("dvc", args, stdout = TRUE, stderr = TRUE)
  
  if (!is.null(attr(result, "status"))) {
    cli::cli_alert_warning("Failed to pull data from DVC remote")
    return(invisible(FALSE))
  }
  
  cli::cli_alert_success("Successfully pulled data from DVC remote")
  invisible(TRUE)
}

#' Push Data to DVC Remote
#'
#' @param path Optional character vector of specific paths to push
#' @param remote Optional name of the remote to push to
#'
#' @return Invisibly returns TRUE if successful
#' @export
dvc_push <- function(path = NULL, remote = NULL) {
  check_dvc()
  
  args <- c("push", 
            if(!is.null(remote)) c("--remote", remote) else NULL,
            path)
  
  result <- system2("dvc", args, stdout = TRUE, stderr = TRUE)
  
  if (!is.null(attr(result, "status"))) {
    cli::cli_alert_warning("Failed to push data to DVC remote")
    return(invisible(FALSE))
  }
  
  cli::cli_alert_success("Successfully pushed data to DVC remote")
  invisible(TRUE)
}

#' Add Files to Git
#'
#' @param path Character vector of file paths to add
#' @param force Logical. Whether to force add ignored files. Default is FALSE.
#'
#' @return Invisibly returns the added paths
#' @export
git_add <- function(path, force = FALSE) {
  check_git()
  
  args <- c("add", if(force) "-f" else NULL, path)
  result <- system2("git", args, stdout = TRUE, stderr = TRUE)
  
  if (!is.null(attr(result, "status"))) {
    cli::cli_alert_warning("Failed to add files to Git")
    return(invisible(FALSE))
  }
  
  cli::cli_alert_success("Added files to Git staging area")
  invisible(path)
}

#' Commit Changes to Git
#'
#' @param message Commit message
#' @param all Logical. Whether to automatically stage modified and deleted files. Default is FALSE.
#'
#' @return Invisibly returns TRUE if successful
#' @export
git_commit <- function(message, all = FALSE) {
  check_git()
  
  args <- c("commit", if(all) "-a" else NULL, "-m", shQuote(message))
  result <- system2("git", args, stdout = TRUE, stderr = TRUE)
  
  if (!is.null(attr(result, "status"))) {
    cli::cli_alert_warning("Failed to commit changes to Git")
    return(invisible(FALSE))
  }
  
  cli::cli_alert_success("Committed changes to Git")
  invisible(TRUE)
}

#' Check DVC Installation
#' @keywords internal
check_dvc <- function() {
  if (system2("which", "dvc", stdout = NULL, stderr = NULL) != 0) {
    stop("DVC is not installed. Please install it first: https://dvc.org/doc/install")
  }
}

#' Check Git Installation
#' @keywords internal
check_git <- function() {
  if (system2("which", "git", stdout = NULL, stderr = NULL) != 0) {
    stop("Git is not installed. Please install it first.")
  }
} 