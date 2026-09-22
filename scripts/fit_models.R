source("R/data.R")
source("R/models.R")

input <- "data/processed/telco.rds"

if (!file.exists(input)) {
  stop("Missing processed data. Run scripts/prepare_data.R first.")
}

telco <- readRDS(input)
groups <- summarize_contracts(telco)

config <- list(
  seed = 321L,
  n_sims = 20000L,
  chains = 4L,
  iter = 2000L,
  warmup = 1000L
)

message("[fit] Computing overall Beta posterior...")

overall <- fit_overall(
  telco,
  seed = config$seed,
  n_sims = config$n_sims
)

message("[fit] Compiling and fitting hierarchical Stan model...")

hierarchical <- fit_hierarchical(
  groups = groups,
  stan_file = "stan/hierarchical_model.stan",
  seed = config$seed,
  chains = config$chains,
  iter = config$iter,
  warmup = config$warmup
)

models <- list(
  groups = groups,
  overall = overall,
  hierarchical = hierarchical,
  config = config,
  session = utils::sessionInfo()
)

dir.create("artifacts", recursive = TRUE, showWarnings = FALSE)
saveRDS(models, "artifacts/models.rds")

capture.output(
  models$session,
  file = "artifacts/sessionInfo.txt"
)

print(overall$summary)
print(hierarchical$diagnostics)

message("[fit] Saved artifacts/models.rds")
