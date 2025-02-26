#' Pipe operator
#'
#' See \code{magrittr::\link[magrittr:pipe]{\%>\%}} for details.
#'
#' @name %>%
#' @rdname pipe
#' @keywords internal
#' @export
#' @importFrom magrittr %>%
#' @usage lhs \%>\% rhs
#' @return The result of applying rhs to lhs
NULL 

#' Format command-line errors into user-friendly messages
#'
#' @param cmd The command that was executed
#' @param output The output from the command
#' @param status The exit status of the command
#' @param default_msg Default message to show if output is empty
#'
#' @return A formatted error message
#' @keywords internal
format_cli_error <- function(cmd, output, status, default_msg = NULL) {
  # If no output and no default message, create a generic one
  if (length(output) == 0 && is.null(default_msg)) {
    if (status == 127) {
      msg <- sprintf("Command '%s' not found. Please ensure it is installed.", cmd)
    } else {
      msg <- sprintf("Command '%s' failed with status %d", cmd, status)
    }
  } else {
    # Use provided output or default message
    msg <- if (length(output) > 0) paste(output, collapse = "\n") else default_msg
  }
  
  # Format the message using cli
  cli::format_error(
    c(
      "!" = msg,
      "i" = "Check the error message above for details.",
      if (status == 127) {
        c("i" = "This usually means the required tool is not installed or not in your PATH.")
      }
    )
  )
}

#' Check if a command is available
#'
#' @param cmd The command to check
#' @param min_version Minimum required version (optional)
#' @param version_cmd Command to get version (defaults to --version)
#' @param version_pattern Regex pattern to extract version
#'
#' @return TRUE if command is available and meets version requirement
#' @keywords internal
check_command <- function(cmd, 
                         min_version = NULL, 
                         version_cmd = "--version",
                         version_pattern = NULL) {
  # Check if command exists
  cmd_path <- Sys.which(cmd)
  if (cmd_path == "") return(FALSE)
  
  # If no version check needed, return TRUE
  if (is.null(min_version)) return(TRUE)
  
  # Get version
  tryCatch({
    version_output <- system2(cmd, version_cmd, stdout = TRUE, stderr = TRUE)
    if (is.null(version_pattern)) {
      # Default pattern matches first version-like string
      version_pattern <- "[0-9]+\\.[0-9]+\\.[0-9]+"
    }
    version <- regmatches(version_output, 
                         regexpr(version_pattern, version_output))[[1]]
    utils::compareVersion(version, min_version) >= 0
  }, error = function(e) FALSE)
}

#' Format command output for display
#'
#' @param output The command output to format
#' @param success Whether the command was successful
#' @param cmd The command that was run
#'
#' @return Formatted output suitable for display
#' @keywords internal
format_cmd_output <- function(output, success = TRUE, cmd = NULL) {
  if (length(output) == 0) return(NULL)
  
  # Format the header
  header <- if (!is.null(cmd)) {
    sprintf("Output from '%s':", cmd)
  } else {
    "Command output:"
  }
  
  # Format the output
  formatted <- paste(output, collapse = "\n")
  
  # Use appropriate cli formatting
  if (success) {
    cli::cli_alert_info(header)
    cli::cli_text(formatted)
  } else {
    cli::cli_alert_danger(header)
    cli::cli_text(formatted)
  }
} 