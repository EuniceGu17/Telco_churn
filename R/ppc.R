# Both tails include ties, so cap the two-sided value at one.
ppc_value <- function(y_rep, observed) {
  stopifnot(length(y_rep) > 0, all(is.finite(y_rep)),
            length(observed) == 1, is.finite(observed))
  min(1, 2 * min(mean(y_rep <= observed), mean(y_rep >= observed)))
}

summarize_results <- function(models) {
  group_data <- models$group_data
  overall <- models$overall
  theta_draws <- models$hierarchical$theta_draws
  yrep_mat <- models$hierarchical$yrep_mat

  theta_summary <- data.frame(
    Contract = as.character(group_data$Contract),
    mean = colMeans(theta_draws),
    lower = apply(theta_draws, 2, quantile, probs = 0.025),
    upper = apply(theta_draws, 2, quantile, probs = 0.975)
  )
  rownames(theta_summary) <- NULL

  group_ppc <- numeric(nrow(group_data))
  for (j in seq_len(nrow(group_data))) {
    group_ppc[j] <- ppc_value(yrep_mat[, j], group_data$y[j])
  }

  ppc_summary <- data.frame(
    group = c("Overall", as.character(group_data$Contract)),
    p_two_sided = c(
      ppc_value(overall$y_rep_total, overall$summary$y), group_ppc
    )
  )

  comparison <- group_data %>%
    mutate(Contract = as.character(Contract)) %>%
    left_join(theta_summary, by = "Contract") %>%
    mutate(expected_y_oneparam = n * overall$summary$mean,
           expected_y_hier = n * mean) %>%
    select(Contract, n, y, expected_y_oneparam, expected_y_hier)

  diagnostics <- models$hierarchical$parameter_summary
  diagnostics$divergences_all_chains <- models$hierarchical$divergences

  list(overall_posterior = overall$summary,
       contract_posterior = theta_summary,
       ppc_summary = ppc_summary,
       model_comparison = comparison,
       mcmc_diagnostics = diagnostics)
}
