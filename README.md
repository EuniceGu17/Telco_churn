# Telco Customer Churn: Reproducible Bayesian Analysis

This project reorganizes my STATS 551 customer churn analysis for STATS 607 Project 1. The original analysis was written in an R notebook. This version separates data preparation, model fitting, posterior predictive checks, and plotting into R functions and scripts that can be run with Make.

The analysis estimates the overall churn probability and compares churn probabilities across three contract types: month-to-month, one year, and two years. The main outputs are posterior summaries, model diagnostics, and eight figures.

## Data

The input is [`data/raw/Telco-Customer-Churn.csv`](https://www.kaggle.com/datasets/blastchar/telco-customer-churn), the dataset used in my STATS 551 project. The pipeline reads this local file and does not download data or require login credentials.

The dataset contains 7,043 customers, including 1,869 who churned. This analysis uses three columns:

| Column | Use |
| --- | --- |
| `customerID` | Check that customer identifiers are present and unique |
| `Churn` | Convert `Yes` and `No` to 1 and 0 |
| `Contract` | Group customers by contract type |

The raw CSV is kept unchanged. Missing values in `TotalCharges` do not cause rows to be dropped because this variable is not used in the analysis.

## Requirements and setup

The development environment uses R 4.5.1 on Apple Silicon macOS. R package versions are recorded in `renv.lock`. The project also requires Git, GNU Make, and a C++ toolchain for compiling the Stan model. `renv` restores R packages; it does not install R or system compilers.

Install R from [CRAN](https://cran.r-project.org/). On macOS, install Apple's Command Line Tools if they are not already available:

```bash
xcode-select --install
```

After installation, check that the required commands are available:

```bash
Rscript --version
git --version
make --version
clang++ --version
```

Clone this repository:

```bash
git clone https://github.com/EuniceGu17/Telco_churn project01
cd project01
Rscript -e 'renv::restore(prompt = FALSE)'
```

The committed `.Rprofile` and `renv/activate.R` bootstrap the project's version of renv. Restoring the environment requires internet access and may take longer than running the analysis, especially if packages need to compile from source. Restore the locked package versions instead of installing the latest versions of RStan and its dependencies separately.

The setup instructions target macOS. Windows and Linux have not been verified for this project. See the [RStan installation guide](https://github.com/stan-dev/rstan/wiki/RStan-Getting-Started) for platform-specific requirements.

## Reproduce the analysis

Run all commands from the repository root. After restoring the environment, regenerate the results with:

```bash
make reproduce
```

This command runs the following stages as needed:

1. `scripts/prepare_data.R` validates the CSV and saves `data/processed/telco.rds`.
2. `scripts/fit_models.R` fits the overall and hierarchical models and saves `artifacts/models.rds`.
3. `scripts/generate_results.R` writes all figures and tables in one invocation.

Output directories are created automatically. The scripts print progress messages and report missing inputs or invalid data as errors. No notebook execution or manual code editing is required.

Once every expected output exists and is nonempty, Make writes `artifacts/results.done`. If the inputs and code are unchanged and all outputs still exist, a second call prints:

```text
Nothing needs to be rebuilt.
```

Changes to dependencies rebuild the affected stages. If a final output is deleted, the full set of figures and tables is regenerated using the saved model results, unless the model also needs rebuilding. Make uses file modification times, so editing an output by hand is not a reliable way to request regeneration.

To remove generated analysis files and rebuild from the CSV:

```bash
make clean
make reproduce
```

`make clean` removes the processed dataset, saved model results, completion marker, and the designated figures and tables. It preserves the raw data, original archive, source code, and R environment. It does not remove any separate Stan compilation cache.

## Models and reproducibility

The overall model uses a `Beta(1, 1)` prior and a binomial likelihood. With 1,869 churns among 7,043 customers, its posterior is `Beta(1870, 5175)`, with a mean of approximately 0.2654 and a 95% credible interval of approximately [0.2552, 0.2758].

The hierarchical model gives each contract type its own churn probability. These probabilities share a Beta distribution with independent `Exponential(1)` priors on its two shape parameters. It is fitted using RStan.

The scripts use seed `321`. The overall model uses 20,000 posterior draws. The Stan model uses four chains, 2,000 iterations per chain, 1,000 warmup iterations per chain, and two CPU cores. Numerical results may differ slightly across platforms and compiler versions.

The workflow also performs posterior predictive checks of churn counts. The two-sided tail calculation includes ties and is capped at one. A large value alone does not establish that the model fits every aspect of the data.

Inspect `results/tables/mcmc_diagnostics.csv` before interpreting the hierarchical estimates. The fitting script warns about divergent transitions or missing/high R-hat values; these warnings do not automatically stop output generation.

## Outputs

Figures are saved in `results/figures/`:

| File | Content |
| --- | --- |
| `churn_bar.png` | Observed churn counts |
| `contract_rate.png` | Observed churn rates by contract type |
| `mc_posterior.png` | Posterior distribution of the overall churn probability |
| `ppc_total.png` | Overall posterior predictive check |
| `theta_density.png` | Posterior densities by contract type |
| `theta_interval.png` | Posterior means and credible intervals by contract type |
| `ppc_contract.png` | Posterior predictive checks by contract type |
| `comparison_models.png` | Observed and model-based expected churn counts |

Tables are saved in `results/tables/`:

| File | Content |
| --- | --- |
| `overall_posterior.csv` | Overall posterior parameters, mean, and credible interval |
| `contract_posterior.csv` | Contract-specific posterior means and credible intervals |
| `ppc_summary.csv` | Two-sided posterior predictive tail values |
| `model_comparison.csv` | Observed counts and expected counts under both models |
| `mcmc_diagnostics.csv` | Parameter summaries, effective sample sizes, R-hat, and total divergences |

The total divergence count is repeated on each parameter row in the diagnostics table; it should not be summed across rows. Intermediate results are stored in `data/processed/` and `artifacts/`. The saved model results also include the sampling settings and R session information.

## Tests

Run the tests with:

```bash
make test
```

The tests use base R assertions and cover two categories:

| Category | File | Checks |
| --- | --- | --- |
| Data validation | `tests/test_data.R` | Expected sample and churn counts, contract-group counts, and rejection of an invalid churn label |
| Function correctness | `tests/test_models.R` | A hand-calculated Beta posterior and rejection of impossible counts |
| Function correctness | `tests/test_ppc.R` | Known predictive-tail examples, including ties and extreme observations |

The tests need the raw CSV and restored R packages, but do not fit the Stan model. A successful run ends with `All tests passed.` These checks do not replace inspecting MCMC diagnostics or verifying the complete reproduction command.

## Repository structure

| Path | Purpose |
| --- | --- |
| `original/` | Preserved notebook and original analysis materials; not used by the active pipeline |
| `data/raw/` | Unmodified input CSV |
| `data/processed/` | Generated analysis-ready dataset |
| `R/` | Functions for data handling, models, predictive checks, and plots |
| `scripts/` | Command-line entry points for each stage and the tests |
| `stan/` | Hierarchical model source |
| `artifacts/` | Generated model results and completion marker |
| `results/figures/` | Generated PNG figures |
| `results/tables/` | Generated CSV summaries |
| `tests/` | Data and function checks |
| `docs/` | Project documentation and reflection |
| `Makefile` | Reproduction, testing, and cleanup targets |
| `renv.lock` | R dependency versions |
| `.renvignore` | Excludes archived materials and generated files from dependency scanning |

The original analysis remains in Git history. Original and final commit hashes are supplied with the assignment submission.
