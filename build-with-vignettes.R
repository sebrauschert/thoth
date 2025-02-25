#!/usr/bin/env Rscript

# Script to build and install the thoth package with vignettes
# This ensures that browseVignettes("thoth") will work

# Clean any previous builds
if (dir.exists("thoth.Rcheck")) {
  unlink("thoth.Rcheck", recursive = TRUE)
}
if (dir.exists("Meta")) {
  unlink("Meta", recursive = TRUE)
}
if (dir.exists("doc")) {
  unlink("doc", recursive = TRUE)
}

# Build vignettes
message("Building vignettes...")
devtools::build_vignettes()

# Build the package with vignettes
message("Building package with vignettes...")
pkg_file <- devtools::build(vignettes = TRUE)

# Install the package with vignettes
message("Installing package with vignettes...")
install.packages(pkg_file, repos = NULL, type = "source")

message("Done! You can now run browseVignettes(\"thoth\") to view the vignettes.") 