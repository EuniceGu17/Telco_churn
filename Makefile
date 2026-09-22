.DEFAULT_GOAL := reproduce
.DELETE_ON_ERROR:

RSCRIPT := Rscript
ENV := $(wildcard renv.lock)
FIG_NAMES := churn_bar contract_rate mc_posterior ppc_total theta_density theta_interval ppc_contract comparison_models
TABLE_NAMES := overall_posterior contract_posterior ppc_summary model_comparison mcmc_diagnostics
FIGURES := $(addprefix results/figures/,$(addsuffix .png,$(FIG_NAMES)))
TABLES := $(addprefix results/tables/,$(addsuffix .csv,$(TABLE_NAMES)))

.PHONY: all reproduce test
all: reproduce
reproduce: $(FIGURES) $(TABLES)

data/processed/telco.rds: data/raw/Telco-Customer-Churn.csv R/data.R scripts/prepare_data.R $(ENV)
	$(RSCRIPT) scripts/prepare_data.R

artifacts/models.rds: data/processed/telco.rds R/data.R R/models.R scripts/fit_models.R stan/hierarchical_model.stan $(ENV)
	$(RSCRIPT) scripts/fit_models.R

$(FIGURES): results/figures/%.png: artifacts/models.rds R/plots.R R/ppc.R scripts/generate_results.R $(ENV)
	$(RSCRIPT) scripts/generate_results.R "$@"

$(TABLES): results/tables/%.csv: artifacts/models.rds R/ppc.R R/plots.R scripts/generate_results.R $(ENV)
	$(RSCRIPT) scripts/generate_results.R "$@"

test:
	$(RSCRIPT) scripts/run_tests.R
