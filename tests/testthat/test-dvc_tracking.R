# Create test environment
library(testthat)
library(toth)
library(readr)
library(withr)
library(tibble)
library(digest)

# Mock DVC commands
mock_dvc_command <- function(args) {
  cmd <- args[1]
  if (cmd == "init") {
    dir.create(".dvc")
    dir.create(".dvc/cache")
    writeLines(c("/data", "/.dvc/cache"), ".gitignore")
    return(character(0))
  } else if (cmd == "add") {
    # Create a mock .dvc file
    dvc_file <- paste0(args[length(args)], ".dvc")
    writeLines(sprintf("outs:\n- md5: %s\n  path: %s\n", 
                      digest::digest(args[length(args)]), 
                      args[length(args)]), dvc_file)
    return(character(0))
  } else if (cmd == "commit") {
    return(character(0))
  }
  return(character(0))
}

# Mock Git commands
mock_git_command <- function(args) {
  return(character(0))
}

# Helper function to create temporary test environment
setup_test_env <- function(mock = TRUE) {
  # Create temp directory
  tmp_dir <- tempfile("toth_test_")
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
    dir.create(".dvc")
    dir.create(".dvc/cache")
    writeLines(c("/data", "/.dvc/cache"), ".gitignore")
  } else {
    # Initialize DVC (mock if not available)
    tryCatch({
      system2("dvc", args = c("init", "--quiet"))
    }, error = function(e) {
      dir.create(".dvc")
      dir.create(".dvc/cache")
      writeLines(c("/data", "/.dvc/cache"), ".gitignore")
    })
  }
  
  tmp_dir
}

# Test DVC installation check
test_that("dvc_track checks for DVC installation", {
  # Create a temporary test environment
  tmp_dir <- setup_test_env(mock = TRUE)
  on.exit(unlink(tmp_dir, recursive = TRUE))
  
  # Create a test file
  writeLines("test", "test.csv")
  
  # Mock the system command to simulate DVC not being installed
  mockery::stub(dvc_track, "system", function(...) 1)
  expect_error(
    dvc_track("test.csv"),
    "DVC is not installed"
  )
})

test_that("dvc_track handles non-existent files correctly", {
  tmp_dir <- setup_test_env(mock = TRUE)
  on.exit(unlink(tmp_dir, recursive = TRUE))
  
  expect_error(
    dvc_track("nonexistent.csv"),
    "File .* does not exist"
  )
})

test_that("dvc_track handles multiple paths correctly", {
  tmp_dir <- setup_test_env(mock = TRUE)
  on.exit(unlink(tmp_dir, recursive = TRUE))
  
  expect_error(
    dvc_track(c("file1.txt", "file2.txt")),
    "Multiple paths are not supported"
  )
})

test_that("write_csv_dvc writes and tracks files correctly", {
  tmp_dir <- setup_test_env(mock = TRUE)
  on.exit(unlink(tmp_dir, recursive = TRUE))
  
  # Test data
  test_data <- tibble(x = 1:3, y = letters[1:3])
  test_file <- "test.csv"
  
  # Test writing and tracking
  expect_silent(
    write_csv_dvc(test_data, test_file, "Test commit")
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
  expect_silent(
    write_csv_dvc(new_data, test_file, "Updated data")
  )
  expect_equal(
    as.data.frame(read_csv(test_file, show_col_types = FALSE)),
    as.data.frame(new_data)
  )
})

test_that("write_rds_dvc writes and tracks files correctly", {
  tmp_dir <- setup_test_env(mock = TRUE)
  on.exit(unlink(tmp_dir, recursive = TRUE))
  
  # Test data
  test_data <- list(a = 1:3, b = letters[1:3])
  test_file <- "test.rds"
  
  # Test writing and tracking
  expect_silent(
    write_rds_dvc(test_data, test_file, "Test commit")
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
  expect_silent(
    write_rds_dvc(test_data, "test_compressed.rds", compress = TRUE)
  )
  expect_equal(
    readRDS("test_compressed.rds"),
    test_data
  )
})

test_that("dvc_track handles messages correctly", {
  tmp_dir <- setup_test_env(mock = TRUE)
  on.exit(unlink(tmp_dir, recursive = TRUE))
  
  # Create a test file
  test_file <- "test.txt"
  writeLines("test", test_file)
  
  # Test tracking with message
  expect_silent(
    dvc_track(test_file, "Test commit message")
  )
  expect_true(file.exists(paste0(test_file, ".dvc")))
  
  # Test tracking without message
  expect_silent(
    dvc_track(test_file)
  )
})

test_that("write functions maintain tidyverse pipe chain", {
  tmp_dir <- setup_test_env(mock = TRUE)
  on.exit(unlink(tmp_dir, recursive = TRUE))
  
  # Test data
  test_data <- tibble(x = 1:3)
  
  # Test pipe chain with write_csv_dvc
  result <- test_data |>
    write_csv_dvc("test.csv") |>
    dplyr::mutate(y = x * 2)
  
  expect_equal(result$y, c(2, 4, 6))
  
  # Test pipe chain with write_rds_dvc
  model <- lm(dist ~ speed, cars)
  result <- model |>
    write_rds_dvc("model.rds") |>
    predict(newdata = data.frame(speed = 20))
  
  expect_type(result, "double")
}) 