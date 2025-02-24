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
#' Adds file contents to the index (staging area).
#'
#' @param path Character vector of file paths to add
#' @param force Logical. Whether to force add ignored files. Default is FALSE.
#'
#' @return Invisibly returns the added paths
#' @export
#'
#' @examples
#' \dontrun{
#' git_add("analysis.R")
#' git_add(c("data/results.csv", "plots/figure1.png"))
#' git_add(".", force = FALSE)  # add all changes
#' }
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
#' Records changes to the repository.
#'
#' @param message Commit message
#' @param all Logical. Whether to automatically stage modified and deleted files. Default is FALSE.
#'
#' @return Invisibly returns TRUE if successful
#' @export
#'
#' @examples
#' \dontrun{
#' git_commit("Add analysis script")
#' git_commit("Update results", all = TRUE)
#' }
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

#' Get Git Status
#'
#' Shows the working tree status, indicating which files have been modified,
#' added, deleted, or untracked.
#'
#' @param short Logical. Whether to show status in short format. Default is TRUE.
#'
#' @return Character vector containing status output
#' @export
#'
#' @examples
#' \dontrun{
#' git_status()
#' git_status(short = FALSE)  # detailed output
#' }
git_status <- function(short = TRUE) {
  check_git()
  
  args <- c("status", if(short) "--short" else NULL)
  result <- system2("git", args, stdout = TRUE, stderr = TRUE)
  
  if (!is.null(attr(result, "status"))) {
    cli::cli_alert_warning("Failed to get Git status")
    return(invisible(NULL))
  }
  
  if (length(result) == 0) {
    cli::cli_alert_info("Working directory clean")
  } else {
    cat(paste(result, collapse = "\n"), "\n")
  }
  
  invisible(result)
}

#' Pull Changes from Git Remote
#'
#' Fetches changes from a remote repository and integrates them into the current branch.
#'
#' @param remote Name of the remote. Default is NULL (uses default remote).
#' @param branch Name of the branch. Default is NULL (uses current branch).
#'
#' @return Invisibly returns TRUE if successful
#' @export
#'
#' @examples
#' \dontrun{
#' git_pull()
#' git_pull("origin", "main")
#' }
git_pull <- function(remote = NULL, branch = NULL) {
  check_git()
  
  args <- c("pull", remote, branch)
  result <- system2("git", args, stdout = TRUE, stderr = TRUE)
  
  if (!is.null(attr(result, "status"))) {
    cli::cli_alert_warning("Failed to pull changes from remote")
    return(invisible(FALSE))
  }
  
  cli::cli_alert_success("Successfully pulled changes")
  invisible(TRUE)
}

#' Push Changes to Git Remote
#'
#' Uploads local branch commits to a remote repository.
#'
#' @param remote Name of the remote. Default is NULL (uses default remote).
#' @param branch Name of the branch. Default is NULL (uses current branch).
#'
#' @return Invisibly returns TRUE if successful
#' @export
#'
#' @examples
#' \dontrun{
#' git_push()
#' git_push("origin", "feature/new-analysis")
#' }
git_push <- function(remote = NULL, branch = NULL) {
  check_git()
  
  args <- c("push", remote, branch)
  result <- system2("git", args, stdout = TRUE, stderr = TRUE)
  
  if (!is.null(attr(result, "status"))) {
    cli::cli_alert_warning("Failed to push changes to remote")
    return(invisible(FALSE))
  }
  
  cli::cli_alert_success("Successfully pushed changes")
  invisible(TRUE)
}

#' Create a New Git Branch
#'
#' Creates a new branch and optionally switches to it.
#'
#' @param branch_name Name of the new branch
#' @param checkout Logical. Whether to checkout the new branch. Default is TRUE.
#'
#' @return Invisibly returns TRUE if successful
#' @export
#'
#' @examples
#' \dontrun{
#' git_branch("feature/new-analysis")
#' git_branch("hotfix/bug-123", checkout = FALSE)
#' }
git_branch <- function(branch_name, checkout = TRUE) {
  check_git()
  
  args <- c("branch", branch_name)
  result <- system2("git", args, stdout = TRUE, stderr = TRUE)
  
  if (!is.null(attr(result, "status"))) {
    cli::cli_alert_warning("Failed to create branch: {branch_name}")
    return(invisible(FALSE))
  }
  
  if (checkout) {
    args <- c("checkout", branch_name)
    result <- system2("git", args, stdout = TRUE, stderr = TRUE)
    
    if (!is.null(attr(result, "status"))) {
      cli::cli_alert_warning("Failed to checkout branch: {branch_name}")
      return(invisible(FALSE))
    }
  }
  
  cli::cli_alert_success("Created{if (checkout) ' and checked out' else ''} branch: {branch_name}")
  invisible(TRUE)
}

#' Checkout a Git Branch
#'
#' Switches to a specified branch, optionally creating it if it doesn't exist.
#'
#' @param branch_name Name of the branch to checkout
#' @param create Logical. Whether to create the branch if it doesn't exist. Default is FALSE.
#'
#' @return Invisibly returns TRUE if successful
#' @export
#'
#' @examples
#' \dontrun{
#' git_checkout("main")
#' git_checkout("feature/new-analysis", create = TRUE)
#' }
git_checkout <- function(branch_name, create = FALSE) {
  check_git()
  
  args <- c("checkout", if(create) "-b" else NULL, branch_name)
  result <- system2("git", args, stdout = TRUE, stderr = TRUE)
  
  if (!is.null(attr(result, "status"))) {
    cli::cli_alert_warning("Failed to checkout branch: {branch_name}")
    return(invisible(FALSE))
  }
  
  cli::cli_alert_success("Checked out branch: {branch_name}")
  invisible(TRUE)
}

#' List Git Branches
#'
#' Shows a list of all branches in the repository.
#'
#' @param all Logical. Whether to show all branches (including remotes). Default is FALSE.
#'
#' @return Character vector of branch names
#' @export
#'
#' @examples
#' \dontrun{
#' git_branch_list()
#' git_branch_list(all = TRUE)  # include remote branches
#' }
git_branch_list <- function(all = FALSE) {
  check_git()
  
  args <- c("branch", if(all) "-a" else NULL)
  result <- system2("git", args, stdout = TRUE, stderr = TRUE)
  
  if (!is.null(attr(result, "status"))) {
    cli::cli_alert_warning("Failed to list branches")
    return(invisible(NULL))
  }
  
  # Clean up branch names
  branches <- gsub("^[\\* ]\\s*", "", result)
  cat(paste(result, collapse = "\n"), "\n")
  
  invisible(branches)
}

#' Get Git Log
#'
#' Shows the commit logs.
#'
#' @param n Number of commits to show. Default is 10.
#' @param oneline Logical. Whether to show each commit on one line. Default is TRUE.
#'
#' @return Character vector containing log output
#' @export
#'
#' @examples
#' \dontrun{
#' git_log()
#' git_log(n = 20, oneline = FALSE)  # detailed log
#' }
git_log <- function(n = 10, oneline = TRUE) {
  # Check if git is installed
  check_git()
  
  # Check if current directory is a git repository
  if (!dir.exists(".git")) {
    cli::cli_alert_warning("Not a Git repository")
    return(invisible(NULL))
  }
  
  # Build command arguments
  args <- c("log")
  if (oneline) args <- c(args, "--oneline")
  if (!is.null(n)) args <- c(args, paste0("-", n))
  
  # Run git command with error handling
  result <- tryCatch({
    system2("git", args, stdout = TRUE, stderr = TRUE)
  }, error = function(e) {
    cli::cli_alert_warning("Error executing Git command: {e$message}")
    return(NULL)
  })
  
  # Check for command failure
  if (!is.null(attr(result, "status"))) {
    cli::cli_alert_warning("Failed to get Git log")
    if (!is.null(result)) {
      cli::cli_alert_info("Git output: {paste(result, collapse = '\n')}")
    }
    return(invisible(NULL))
  }
  
  # If no commits yet, show appropriate message
  if (length(result) == 0) {
    cli::cli_alert_info("No commits yet")
    return(invisible(NULL))
  }
  
  # Display results
  cat(paste(result, collapse = "\n"), "\n")
  invisible(result)
}

#' Create a DVC Stage
#'
#' @param name Stage name
#' @param cmd Command to execute
#' @param deps Dependencies
#' @param outs Outputs
#' @param metrics Logical or character vector indicating whether to track metrics
#' @param plots Logical or character vector indicating whether to track plots
#' @param params Named list of parameters
#' @param always_changed Logical indicating whether the stage should always be re-run
#'
#' @return Invisibly returns TRUE if successful
#' @export
dvc_stage <- function(name, cmd, deps = NULL, outs = NULL, 
                     metrics = FALSE, plots = FALSE, 
                     params = NULL, always_changed = FALSE) {
  check_dvc()
  
  # Build the dvc stage add command
  args <- c("stage", "add", "-n", name)
  
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
  
  # Add the command as a positional argument at the end
  args <- c(args, shQuote(cmd))
  
  # Run the command with error handling
  result <- tryCatch({
    system2("dvc", args, stdout = TRUE, stderr = TRUE)
  }, error = function(e) {
    cli::cli_alert_warning("Error executing DVC command: {e$message}")
    return(NULL)
  })
  
  # Check for command failure
  if (!is.null(attr(result, "status"))) {
    cli::cli_alert_warning("Failed to create DVC stage: {name}")
    if (!is.null(result)) {
      cli::cli_alert_info("DVC output: {paste(result, collapse = '\n')}")
    }
    return(invisible(FALSE))
  }
  
  cli::cli_alert_success("Created DVC stage: {name}")
  invisible(TRUE)
} 