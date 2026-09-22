project_root <- normalizePath(".", mustWork = TRUE)

source("R/data.R")
source("R/models.R")
source("R/ppc.R")

# Wrap only the file-reading function for tests using project-relative paths.
read_telco_original <- read_telco
read_telco <- function(path) {
  read_telco_original(file.path(project_root, path))
}

testthat::test_dir(
  "tests/testthat",
  reporter = "summary",
  stop_on_failure = TRUE
)
