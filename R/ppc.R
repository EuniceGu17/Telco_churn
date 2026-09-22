# Calculate a capped two-sided posterior predictive tail probability.
ppc_two_sided <- function(y_rep, observed) {
  if (!is.numeric(y_rep) || length(y_rep) == 0L ||
      any(!is.finite(y_rep)) ||
      !is.numeric(observed) || length(observed) != 1L ||
      !is.finite(observed)) {
    stop("PPC inputs must be finite numeric values.")
  }

  min(
    1,
    2 * min(
      mean(y_rep <= observed),
      mean(y_rep >= observed)
    )
  )
}


# Summarize group-level posterior draws in the stored group order.
contract_summary <- function(models) {
  theta <- models$hierarchical$theta
  groups <- models$groups

  if (ncol(theta) != nrow(groups)) {
    stop("Posterior columns do not match contract groups.")
  }

  data.frame(
    Contract = as.character(groups$Contract),
    mean = colMeans(theta),
    lower = apply(
      theta, 2, stats::quantile,
      probs = 0.025, names = FALSE
    ),
    upper = apply(
      theta, 2, stats::quantile,
      probs = 0.975, names = FALSE
    )
  )
}


# Build all final numerical tables from the saved model results.
make_tables <- function(models) {
  groups <- models$groups
  overall <- models$overall
  hierarchical <- models$hierarchical

  contract <- contract_summary(models)

  group_ppc <- vapply(
    seq_len(nrow(groups)),
    function(j) {
      ppc_two_sided(
        hierarchical$y_rep[, j],
        groups$y[j]
      )
    },
    numeric(1)
  )

  ppc <- data.frame(
    scope = c("Overall", as.character(groups$Contract)),
    p_two_sided = c(
      ppc_two_sided(
        overall$y_rep,
        overall$summary$y
      ),
      group_ppc
    )
  )

  comparison <- data.frame(
    Contract = as.character(groups$Contract),
    observed = groups$y,
    hierarchical = groups$n * contract$mean,
    one_parameter = groups$n * overall$summary$mean
  )

  list(
    overall_posterior = overall$summary,
    contract_posterior = contract,
    ppc_summary = ppc,
    model_comparison = comparison,
    mcmc_diagnostics = hierarchical$diagnostics,
    parameter_summary = hierarchical$parameter_summary
  )
}
