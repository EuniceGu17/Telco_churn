# Project 1 Reflection

Yiwu Gu | STATS 607

My original STATS 551 project analyzed Telco customer churn using an overall Beta-Binomial model and a hierarchical model by contract type. Most of the R code was in one notebook, with the data, Stan source, report, and figures stored together. Reproducing the analysis required knowing which cells to run and in what order. Package versions were not recorded, so a working notebook on my computer was not enough to make the project easy for someone else to run.

I preserved the original analysis in Git and moved the archived files into `original/`. I then separated data preparation, model fitting, posterior predictive checks, and plotting into functions under `R/` and executable scripts under `scripts/`. The main challenge was making the stages work independently without relying on objects left in a notebook session. Saving the processed data and model draws made the inputs and outputs of each stage explicit.

Environment setup was another challenge. The hierarchical model failed with a missing TBB symbol while loading compiled Stan code. Investigating the installed package versions pointed to a dependency compatibility problem. The lock file now records RStan 2.32.7, StanHeaders 2.32.10, and RcppParallel 5.1.11. I also excluded the archived notebook from dependency scanning so that packages used only in the old workflow would not become requirements for the new one.

The most useful improvements were the Makefile, the recorded environment, and the tests. `make reproduce` connects the analysis stages and avoids unnecessary reruns when the inputs are unchanged. Data checks catch invalid labels and unexpected counts, while small examples check the posterior and predictive-tail calculations. Refactoring also exposed a detail in the original two-sided predictive check: including ties in both tails could produce a value above one. The revised function caps the value at one and has a test for this case.

I used ChatGPT/Codex to give suggestions that help split the notebook into files, draft the Makefile and documentation, and investigate error messages. Running the scripts locally exposed the Stan dependency error; the printed overall posterior also matched the expected mean of about 0.2654. The repository includes automated checks, but their presence alone does not establish that a fresh installation works. A complete run from a new clone is the remaining verification step before submission.

In a future project, I would record dependencies and separate functions from execution scripts from the beginning. I would also test setup instructions in a fresh clone earlier, rather than leaving environment problems until the end.

**Approximate time spent:** organizing files and Git history: 20 minutes; refactoring R and Stan code: 1 hour and 40 minutes; environment setup and debugging: 40 minutes; Makefile and tests: 1 hour; documentation and final verification: 2 hours.
