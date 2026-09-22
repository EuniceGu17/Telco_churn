library(dplyr)
library(rstan)
source("R/data.R")
source("R/models.R")

if (!file.exists("data/processed/telco.rds")) {
  stop("Run Rscript scripts/prepare_data.R first.")
}
telco <- readRDS("data/processed/telco.rds")
group_data <- summarize_contracts(telco)

message("Fitting the overall model...")
overall <- fit_overall(telco)
print(overall$summary)

message("Fitting the hierarchical model...")
hierarchical <- fit_hierarchical(group_data, "stan/hierarchical_model.stan")

models <- list(group_data = group_data, overall = overall,
               hierarchical = hierarchical,
               settings = list(seed = 321, n_sims = 20000,
                               iter = 2000, warmup = 1000, chains = 4, cores = 2),
               session = sessionInfo())

dir.create("artifacts", showWarnings = FALSE)
saveRDS(models, "artifacts/models.rds")
message("Saved artifacts/models.rds")
