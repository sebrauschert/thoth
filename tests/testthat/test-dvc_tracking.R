# Create test environment
library(testthat)
library(thoth)
library(readr)
library(withr)
library(tibble)
library(digest)
library(dplyr)
library(cli)

# Mock system commands
mock_system2 <- function(cmd, args, ...) {
  result <- character(0)
  attr(result, "status") <- 0
  
  if (cmd == "dvc") {
    if (args[1] == "add") {
      # Create mock .dvc file
      # Find the actual file path (after any flags)
      file_path <- args[length(args)]  # Get the last argument which should be the file path
      dvc_file <- paste0(file_path, ".dvc")
      writeLines(sprintf("outs:\n- md5: %s\n  path: %s\n", 
                        digest::digest(file_path), 
                        file_path), dvc_file)
    }
  }
  result
}

# Helper function to create temporary test environment
setup_test_env <- function() {
  # Create temp directory
  tmp_dir <- tempfile("thoth_test_")
  dir.create(tmp_dir)
  withr::local_dir(tmp_dir)
  
  # Create necessary directories
  dir.create(".dvc", showWarnings = FALSE)
  dir.create(".dvc/cache", showWarnings = FALSE)
  writeLines(c("/data", "/.dvc/cache"), ".gitignore")
  
  tmp_dir
}

test_that("dvc_track handles missing DVC gracefully", {
  tmp_dir <- setup_test_env()
  on.exit(unlink(tmp_dir, recursive = TRUE))
  
  # Create a test file
  writeLines("test", "test.csv")
  
  # Mock check_command to simulate missing DVC
  mockery::stub(dvc_track, "check_command", FALSE)
  
  # Test DVC installation check
  withr::with_options(list(cli.num_colors = 1), {
    output <- capture.output({
      result <- dvc_track("test.csv", "Test message")
    }, type = "message")
  })
  
  # Check messages and behavior
  expect_true(any(grepl("DVC is not installed or not found in PATH", output)))
  expect_true(any(grepl("Creating mock .dvc file instead", output)))
  expect_true(file.exists("test.csv.dvc"))
  expect_equal(result, "test.csv")
})

test_that("dvc_track works when DVC is available", {
  tmp_dir <- setup_test_env()
  on.exit(unlink(tmp_dir, recursive = TRUE))
  
  # Create test file
  writeLines("test", "test.txt")
  
  # Mock check_command and system2
  mockery::stub(dvc_track, "check_command", TRUE)
  mockery::stub(dvc_track, "system2", mock_system2)
  
  # Test tracking with message
  withr::with_options(list(cli.num_colors = 1), {
    output <- capture.output({
      result <- dvc_track("test.txt", "Test message")
    }, type = "message")
  })
  
  # Check success messages and behavior
  expect_true(file.exists("test.txt.dvc"))
  expect_equal(result, "test.txt")
})

test_that("write_csv_dvc writes and tracks files correctly", {
  tmp_dir <- setup_test_env()
  on.exit(unlink(tmp_dir, recursive = TRUE))
  
  # Test data
  test_data <- data.frame(a = 1:3, b = letters[1:3])
  
  # Mock dvc_track
  mockery::stub(write_csv_dvc, "dvc_track", function(path, message = NULL, push = FALSE) {
    # Create mock .dvc file
    dvc_file <- paste0(path, ".dvc")
    writeLines(sprintf("outs:\n- md5: %s\n  path: %s\n", 
                      digest::digest(path), 
                      path), dvc_file)
    invisible(path)
  })
  
  # Test writing and tracking
  result <- write_csv_dvc(test_data, "test.csv", message = "Test commit")
  
  # Check results
  expect_true(file.exists("test.csv"))
  expect_true(file.exists("test.csv.dvc"))
  expect_equal(
    as.data.frame(read_csv("test.csv", show_col_types = FALSE)),
    test_data
  )
  expect_equal(result, test_data)
})

test_that("write functions maintain tidyverse pipe chain", {
  tmp_dir <- setup_test_env()
  on.exit(unlink(tmp_dir, recursive = TRUE))
  
  # Test data
  test_data <- data.frame(a = 1:3, b = letters[1:3])
  
  # Mock dvc_track
  mockery::stub(write_csv_dvc, "dvc_track", function(path, message = NULL, push = FALSE) {
    # Create mock .dvc file
    dvc_file <- paste0(path, ".dvc")
    writeLines(sprintf("outs:\n- md5: %s\n  path: %s\n", 
                      digest::digest(path), 
                      path), dvc_file)
    invisible(path)
  })
  
  # Test pipe chain
  result <- dplyr::mutate(test_data, c = a * 2) %>%
    write_csv_dvc("test.csv", message = "Test commit")
  
  # Check results
  expect_equal(result, dplyr::mutate(test_data, c = a * 2))
  expect_true(file.exists("test.csv"))
  expect_true(file.exists("test.csv.dvc"))
})

test_that("write_rds_dvc writes and tracks files correctly", {
  tmp_dir <- setup_test_env()
  on.exit(unlink(tmp_dir, recursive = TRUE))
  
  # Test data
  test_data <- list(a = 1:3, b = letters[1:3])
  
  # Mock dvc_track
  mockery::stub(write_rds_dvc, "dvc_track", function(path, message = NULL, push = FALSE) {
    # Create mock .dvc file
    dvc_file <- paste0(path, ".dvc")
    writeLines(sprintf("outs:\n- md5: %s\n  path: %s\n", 
                      digest::digest(path), 
                      path), dvc_file)
    invisible(path)
  })
  
  # Test writing and tracking
  result <- write_rds_dvc(test_data, "test.rds", message = "Test commit")
  
  # Check results
  expect_true(file.exists("test.rds"))
  expect_true(file.exists("test.rds.dvc"))
  expect_equal(readRDS("test.rds"), test_data)
  expect_equal(result, test_data)
}) 