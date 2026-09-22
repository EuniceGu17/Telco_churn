.DEFAULT_GOAL := reproduce
.DELETE_ON_ERROR:

RSCRIPT := Rscript
ENV := $(wildcard renv.lock)

DATA := data/processed/telco.rds
MODEL := artifacts/models.rds
STAMP := artifacts/results.done

FIG_NAMES := churn_bar contract_rate mc_posterior ppc_total theta_density theta_interval ppc_contract comparison_models
TABLE_NAMES := overall_posterior contract_posterior ppc_summary model_comparison mcmc_diagnostics
FIGURES := $(addprefix results/figures/,$(addsuffix .png,$(FIG_NAMES)))
TABLES := $(addprefix results/tables/,$(addsuffix .csv,$(TABLE_NAMES)))
OUTPUTS := $(FIGURES) $(TABLES)

.PHONY: all reproduce test clean FORCE
all: reproduce

# Check first so an unchanged project prints a clear message.
reproduce:
	@status=0; $(MAKE) --no-print-directory -q $(STAMP) || status=$$?; \
	if [ $$status -eq 0 ]; then \
		echo "Nothing needs to be rebuilt."; \
	elif [ $$status -eq 1 ]; then \
		$(MAKE) --no-print-directory $(STAMP); \
	else \
		exit $$status; \
	fi

$(DATA): data/raw/Telco-Customer-Churn.csv R/data.R scripts/prepare_data.R $(ENV) Makefile
	$(RSCRIPT) scripts/prepare_data.R

$(MODEL): $(DATA) R/data.R R/models.R scripts/fit_models.R stan/hierarchical_model.stan $(ENV) Makefile
	$(RSCRIPT) scripts/fit_models.R

# One script call writes all figures and tables.
# Remove the old marker before running; failures must not look complete.
$(STAMP): $(MODEL) R/plots.R R/ppc.R scripts/generate_results.R $(ENV) Makefile
	rm -f $(STAMP)
	$(RSCRIPT) scripts/generate_results.R
	@for file in $(OUTPUTS); do \
		if [ ! -s "$$file" ]; then \
			echo "Missing or empty output: $$file" >&2; exit 1; \
		fi; \
	done
	touch $(STAMP)

# A completion marker alone is not enough if an output was deleted.
ifneq ($(words $(wildcard $(OUTPUTS))),$(words $(OUTPUTS)))
$(STAMP): FORCE
endif
FORCE:

test:
	$(RSCRIPT) scripts/run_tests.R

# Remove only this pipeline's generated files.
clean:
	rm -f $(DATA) $(MODEL) $(STAMP) $(OUTPUTS)
