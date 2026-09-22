source("R/ppc.R")
source("R/plots.R")

input <- "artifacts/models.rds"

if (!file.exists(input)) {
  stop("Missing model results. Run scripts/fit_models.R first.")
}

models <- readRDS(input)
tables <- make_tables(models)

figure_names <- c(
  "churn_bar",
  "contract_rate",
  "mc_posterior",
  "ppc_total",
  "theta_density",
  "theta_interval",
  "ppc_contract",
  "comparison_models"
)

table_paths <- paste0(
  "results/tables/", names(tables), ".csv"
)

figure_paths <- paste0(
  "results/figures/", figure_names, ".png"
)

allowed <- c(table_paths, figure_paths)
args <- commandArgs(trailingOnly = TRUE)

requested <- if (length(args) == 0L) allowed else args

if (!all(requested %in% allowed)) {
  stop(
    "Unsupported output path: ",
    paste(setdiff(requested, allowed), collapse = ", ")
  )
}

plots <- NULL

if (any(requested %in% figure_paths)) {
  plots <- make_plots(models, tables)
}

for (path in requested) {
  dir.create(
    dirname(path),
    recursive = TRUE,
    showWarnings = FALSE
  )

  key <- tools::file_path_sans_ext(basename(path))

  if (path %in% table_paths) {
    readr::write_csv(tables[[key]], path)
  } else {
    ggplot2::ggsave(
      filename = path,
      plot = plots[[key]],
      width = 9,
      height = 5,
      dpi = 300,
      bg = "white"
    )
  }

  message("[results] Saved ", path)
}
