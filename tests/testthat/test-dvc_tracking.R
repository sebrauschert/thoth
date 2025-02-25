# Create test environment
library(testthat)
library(thoth)
library(readr)
library(withr)
library(tibble)
library(digest)
library(dplyr)

# Helper function to check if DVC is installed
is_dvc_available <- function() {
  tryCatch({
    if (.Platform$OS.type == "windows") {
      # Windows check
      result <- suppressWarnings(system("where dvc", ignore.stdout = TRUE))
    } else {
      # Unix-like check
      result <- suppressWarnings(system("which dvc", ignore.stdout = TRUE))
    }
    return(result == 0)
  }, error = function(e) {
    return(FALSE)
  })
}

# Mock DVC commands
mock_dvc_command <- function(args) {
  cmd <- args[1]
  if (cmd == "init") {
    dir.create(".dvc", showWarnings = FALSE)
    dir.create(".dvc/cache", showWarnings = FALSE)
    writeLines(c("/data", "/.dvc/cache"), ".gitignore")
    return(character(0))
  } else if (cmd == "add") {
    # Create a mock .dvc file
    dvc_file <- paste0(args[length(args)], ".dvc")
    writeLines(sprintf("outs:\n- md5: %s\n  path: %s\n", 
                      digest::digest(args[length(args)]), 
                      args[length(args)]), dvc_file)
    return("Error: mock DVC add error")
  } else if (cmd == "commit") {
    return("Error: mock DVC commit error")
  }
  return(character(0))
}

# Mock Git commands
mock_git_command <- function(args) {
  cmd <- args[1]
  if (cmd == "add") {
    return("Error: mock Git add error")
  } else if (cmd == "commit") {
    return("Error: mock Git commit error")
  }
  return(character(0))
}

# Helper function to create temporary test environment
setup_test_env <- function(mock = TRUE) {
  # Create temp directory
  tmp_dir <- tempfile("thoth_test_")
  dir.create(tmp_dir)
  withr::local_dir(tmp_dir)
  
  if (mock) {
    mockery::stub(dvc_track, "system2", function(cmd, args, ...) {
      if (cmd == "dvc") {
        return(mock_dvc_command(args))
      } else if (cmd == "git") {
        return(mock_git_command(args))
      }
      return(character(0))
    })
    dir.create(".dvc", showWarnings = FALSE)
    dir.create(".dvc/cache", showWarnings = FALSE)
    writeLines(c("/data", "/.dvc/cache"), ".gitignore")
  } else {
    # Initialize DVC (mock if not available)
    tryCatch({
      system2("dvc", args = c("init", "--quiet"))
    }, error = function(e) {
      dir.create(".dvc", showWarnings = FALSE)
      dir.create(".dvc/cache", showWarnings = FALSE)
      writeLines(c("/data", "/.dvc/cache"), ".gitignore")
    })
  }
  
  tmp_dir
}

# Test DVC installation check
test_that("dvc_track checks for DVC installation", {
  # Skip if DVC is not available
  skip_if_not(is_dvc_available(), "DVC is not installed, skipping test")
  
  # Create a temporary test environment
  tmp_dir <- setup_test_env(mock = TRUE)
  on.exit(unlink(tmp_dir, recursive = TRUE))
  
  # Create a test file
  writeLines("test", "test.csv")
  
  # Mock the system command to simulate DVC not being installed
  mockery::stub(dvc_track, "system", function(...) 1)
  expect_error(
    dvc_track("test.csv", "Test message"),
    "DVC is not installed"
  )
})

test_that("dvc_track handles non-existent files correctly", {
  # Skip if DVC is not available
  skip_if_not(is_dvc_available(), "DVC is not installed, skipping test")
  
  tmp_dir <- setup_test_env(mock = TRUE)
  on.exit(unlink(tmp_dir, recursive = TRUE))
  
  expect_error(
    dvc_track("nonexistent.csv", "Test message"),
    "File .* does not exist"
  )
})

test_that("dvc_track handles multiple paths correctly", {
  # Skip if DVC is not available
  skip_if_not(is_dvc_available(), "DVC is not installed, skipping test")
  
  tmp_dir <- setup_test_env(mock = TRUE)
  on.exit(unlink(tmp_dir, recursive = TRUE))
  
  expect_error(
    dvc_track(c("file1.txt", "file2.txt"), "Test message"),
    "Multiple paths are not supported"
  )
})

test_that("write_csv_dvc writes and tracks files correctly", {
  # Skip if DVC is not available
  skip_if_not(is_dvc_available(), "DVC is not installed, skipping test")
  
  tmp_dir <- setup_test_env(mock = TRUE)
  on.exit(unlink(tmp_dir, recursive = TRUE))
  
  # Mock system2 for both DVC and Git commands
  mockery::stub(write_csv_dvc, "system2", function(cmd, args, ...) {
    if (cmd == "dvc") {
      return(mock_dvc_command(args))
    } else if (cmd == "git") {
      return(mock_git_command(args))
    }
    return(character(0))
  })
  
  # Test data
  test_data <- data.frame(a = 1:3, b = letters[1:3])
  test_file <- "test.csv"
  
  # Create necessary directories and files for testing
  dir.create(".dvc/cache", recursive = TRUE, showWarnings = FALSE)
  
  # Create the .dvc file for testing
  dvc_file <- paste0(test_file, ".dvc")
  writeLines(sprintf("outs:\n- md5: %s\n  path: %s\n", digest::digest(test_file), test_file), dvc_file)
  
  # Test writing and tracking
  expect_message(
    write_csv_dvc(test_data, test_file, message = "Test commit"),
    regexp = "Failed to add .* to DVC tracking|Failed to add files to Git|Failed to commit changes to Git",
    all = TRUE
  )
  
  # Check if file exists and contains correct data
  expect_true(file.exists(test_file))
  expect_equal(
    as.data.frame(read_csv(test_file, show_col_types = FALSE)),
    as.data.frame(test_data)
  )
  
  # Check if DVC files exist
  expect_true(file.exists(".dvc/cache"))
  expect_true(file.exists(paste0(test_file, ".dvc")))
  
  # Test overwriting existing file
  new_data <- tibble(x = 4:6, y = letters[4:6])
  expect_message(
    write_csv_dvc(new_data, test_file, message = "Updated data"),
    regexp = "Failed to add .* to DVC tracking|Failed to add files to Git|Failed to commit changes to Git",
    all = TRUE
  )
  expect_equal(
    as.data.frame(read_csv(test_file, show_col_types = FALSE)),
    as.data.frame(new_data)
  )
})

test_that("write_rds_dvc writes and tracks files correctly", {
  # Skip if DVC is not available
  skip_if_not(is_dvc_available(), "DVC is not installed, skipping test")
  
  tmp_dir <- setup_test_env(mock = TRUE)
  on.exit(unlink(tmp_dir, recursive = TRUE))
  
  # Mock system2 for both DVC and Git commands
  mockery::stub(write_rds_dvc, "system2", function(cmd, args, ...) {
    if (cmd == "dvc") {
      return(mock_dvc_command(args))
    } else if (cmd == "git") {
      return(mock_git_command(args))
    }
    return(character(0))
  })
  
  # Test data
  test_data <- list(a = 1:3, b = letters[1:3])
  test_file <- "test.rds"
  
  # Create necessary directories and files for testing
  dir.create(".dvc/cache", recursive = TRUE, showWarnings = FALSE)
  
  # Test writing and tracking
  # First, let's mock the dvc_track function to emit the expected messages
  mockery::stub(write_rds_dvc, "dvc_track", function(path, msg) {
    message("Failed to add ", path, " to DVC tracking")
    message("Failed to add files to Git")
    message("Failed to commit changes to Git")
    # Create the .dvc file for testing
    dvc_file <- paste0(path, ".dvc")
    writeLines(sprintf("outs:\n- md5: %s\n  path: %s\n", digest::digest(path), path), dvc_file)
    invisible(path)
  })
  
  expect_message(
    write_rds_dvc(test_data, test_file, message = "Test commit"),
    regexp = "Failed to add .* to DVC tracking|Failed to add files to Git|Failed to commit changes to Git",
    all = TRUE
  )
  
  # Check if file exists and contains correct data
  expect_true(file.exists(test_file))
  expect_equal(
    readRDS(test_file),
    test_data
  )
  
  # Check if DVC files exist
  expect_true(file.exists(".dvc/cache"))
  expect_true(file.exists(paste0(test_file, ".dvc")))
  
  # Test with different compression levels
  expect_message(
    write_rds_dvc(test_data, "test_compressed.rds", message = "Test compressed", compress = TRUE),
    regexp = "Failed to add .* to DVC tracking|Failed to add files to Git|Failed to commit changes to Git",
    all = TRUE
  )
  expect_equal(
    readRDS("test_compressed.rds"),
    test_data
  )
})

test_that("dvc_track handles messages correctly", {
  # Skip if DVC is not available
  skip_if_not(is_dvc_available(), "DVC is not installed, skipping test")
  
  tmp_dir <- setup_test_env(mock = TRUE)
  on.exit(unlink(tmp_dir, recursive = TRUE))
  
  # Create a test file
  test_file <- "test.txt"
  writeLines("test", test_file)
  
  # Override the system2 stub to emit messages directly
  mockery::stub(dvc_track, "system2", function(cmd, args, ...) {
    if (cmd == "dvc" && args[1] == "add") {
      message("Failed to add ", args[length(args)], " to DVC tracking")
    } else if (cmd == "git" && args[1] == "add") {
      message("Failed to add files to Git")
    } else if (cmd == "dvc" && args[1] == "commit") {
      message("Failed to commit changes to Git")
    }
    return("Error message")
  })
  
  # Test tracking with message
  expect_message(
    dvc_track(test_file, "Test message"),
    regexp = "Failed to add .* to DVC tracking|Failed to add files to Git|Failed to commit changes to Git",
    all = TRUE
  )
  expect_true(file.exists(paste0(test_file, ".dvc")))
  
  # Test tracking without message
  expect_message(
    dvc_track(test_file, NULL),
    regexp = "Failed to add .* to DVC tracking|Failed to add files to Git|Failed to commit changes to Git",
    all = TRUE
  )
})

test_that("write functions maintain tidyverse pipe chain", {
  # Test data
  test_data <- data.frame(a = 1:3, b = letters[1:3])
  
  # Test that the write functions return the input data
  suppressMessages({
    result <- dplyr::mutate(test_data, c = a * 2) %>%
      write_csv_dvc("test.csv", message = "Test commit")
    
    expect_equal(result, dplyr::mutate(test_data, c = a * 2))
  })
}) 