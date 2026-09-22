library(dplyr)
library(tidyr)
library(ggplot2)
source("R/ppc.R")
source("R/plots.R")

if (!file.exists("artifacts/models.rds")) {
  stop("Run Rscript scripts/fit_models.R first.")
}
models <- readRDS("artifacts/models.rds")
tables <- summarize_results(models)
theme_set(theme_minimal())

figure_names <- c("churn_bar", "contract_rate", "mc_posterior", "ppc_total",
                  "theta_density", "theta_interval", "ppc_contract",
                  "comparison_models")
figure_paths <- paste0("results/figures/", figure_names, ".png")
table_paths <- paste0("results/tables/", names(tables), ".csv")
all_outputs <- c(figure_paths, table_paths)

# No arguments: write everything. Make can also request one output at a time.
outputs <- commandArgs(trailingOnly = TRUE)
if (length(outputs) == 0) outputs <- all_outputs
if (!all(outputs %in% all_outputs)) stop("Unknown output filename.")

if (any(outputs %in% figure_paths)) plots <- make_plots(models, tables)

for (path in outputs) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  name <- tools::file_path_sans_ext(basename(path))
  if (path %in% figure_paths) {
    ggsave(path, plot = plots[[name]], width = 9, height = 5, dpi = 300)
  } else {
    readr::write_csv(tables[[name]], path)
  }
  message("Saved ", path)
}
