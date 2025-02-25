#!/usr/bin/env Rscript

# Test script to verify package build and check
library(devtools)

# Build the package
cat("Building package...\n")
build_result <- build()
cat("Build result:", build_result, "\n")

# Check the package
cat("Checking package...\n")
check_result <- check()
cat("Check result:", check_result$status, "\n")

# If there are any errors, print them
if (length(check_result$errors) > 0) {
  cat("Errors:\n")
  print(check_result$errors)
}

# If there are any warnings, print them
if (length(check_result$warnings) > 0) {
  cat("Warnings:\n")
  print(check_result$warnings)
}

# If there are any notes, print them
if (length(check_result$notes) > 0) {
  cat("Notes:\n")
  print(check_result$notes)
}

cat("Test completed.\n") 