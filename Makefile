.DEFAULT_GOAL := all
.DELETE_ON_ERROR:

RSCRIPT := Rscript

RAW := data/raw/Telco-Customer-Churn.csv
PROCESSED := data/processed/telco.rds
MODELS := artifacts/models.rds

FIGURE_NAMES := churn_bar contract_rate mc_posterior ppc_total \
                theta_density theta_interval ppc_contract comparison_models

TABLE_NAMES := overall_posterior contract_posterior ppc_summary \
               model_comparison mcmc_diagnostics parameter_summary

FIGURES := $(addprefix results/figures/,$(addsuffix .png,$(FIGURE_NAMES)))
TABLES := $(addprefix results/tables/,$(addsuffix .csv,$(TABLE_NAMES)))

OUTPUTS := $(FIGURES) $(TABLES)

.PHONY: all reproduce setup test clean

all: reproduce

reproduce: $(OUTPUTS)

setup:
	$(RSCRIPT) -e 'renv::restore(prompt = FALSE)'

$(PROCESSED): $(RAW) R/data.R scripts/prepare_data.R renv.lock
	$(RSCRIPT) scripts/prepare_data.R

$(MODELS): $(PROCESSED) R/data.R R/models.R \
           stan/hierarchical_model.stan scripts/fit_models.R renv.lock
	$(RSCRIPT) scripts/fit_models.R

$(FIGURES): results/figures/%.png: $(MODELS) R/plots.R R/ppc.R \
            scripts/generate_results.R renv.lock
	$(RSCRIPT) scripts/generate_results.R "$@"

$(TABLES): results/tables/%.csv: $(MODELS) R/ppc.R \
          scripts/generate_results.R renv.lock
	$(RSCRIPT) scripts/generate_results.R "$@"

test:
	$(RSCRIPT) scripts/run_tests.R

clean:
	$(RM) $(PROCESSED) $(MODELS) $(OUTPUTS) artifacts/sessionInfo.txt
	