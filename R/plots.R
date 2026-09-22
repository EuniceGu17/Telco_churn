# The plotting code follows the order of the original notebook.
make_plots <- function(models, tables) {
  group_data <- models$group_data
  overall <- models$overall
  n <- overall$summary$n
  y <- overall$summary$y

  counts <- data.frame(
    Churn = factor(c("No", "Yes"), levels = c("No", "Yes")),
    n = c(n - y, y)
  )
  plot_churn_bar <- ggplot(counts, aes(Churn, n)) +
    geom_col(fill = "lightblue") +
    geom_text(aes(label = n), vjust = -0.5) +
    labs(title = "Overall churn counts", x = "Churn", y = "Count")

  churn_by_contract <- group_data %>% mutate(churn_rate = y / n)
  plot_contract_rate <- ggplot(churn_by_contract, aes(Contract, churn_rate)) +
    geom_col(fill = "lightblue") +
    geom_text(aes(label = scales::percent(churn_rate, accuracy = 0.1)),
              vjust = -0.5) +
    scale_y_continuous(labels = scales::percent_format()) +
    labs(title = "Churn rate by contract type", x = "Contract", y = "Churn rate")

  theta_df <- data.frame(theta = overall$theta_samples)
  plot_mc_posterior <- ggplot(theta_df, aes(theta)) +
    geom_histogram(binwidth = 0.001, fill = "lightblue", color = "white") +
    labs(title = "Posterior draws of overall churn probability",
         x = expression(theta), y = "Frequency")

  yrep_total_df <- data.frame(y_rep = overall$y_rep_total)
  ppc_total_hist <- ggplot(yrep_total_df, aes(y_rep)) +
    geom_histogram(bins = 30, fill = "lightblue", color = "white") +
    geom_vline(xintercept = y, color = "red", linetype = "dashed") +
    labs(title = "Posterior predictive distribution of total churn",
         x = "Simulated churn count", y = "Frequency")

  theta_df <- as.data.frame(models$hierarchical$theta_draws)
  names(theta_df) <- as.character(group_data$Contract)
  theta_df <- theta_df %>%
    pivot_longer(everything(), names_to = "Contract", values_to = "theta")

  plot_theta_contract_density <- ggplot(theta_df, aes(theta, fill = Contract)) +
    geom_density(alpha = 0.4) +
    labs(title = "Posterior churn probability by contract type",
         x = expression(theta[j]), y = "Density")

  theta_summary <- tables$contract_posterior
  plot_theta_contract_interval <- ggplot(theta_summary, aes(Contract, mean)) +
    geom_point(size = 3) +
    geom_errorbar(aes(ymin = lower, ymax = upper), width = 0.1) +
    scale_y_continuous(labels = scales::percent_format()) +
    labs(title = "Posterior means and 95% credible intervals",
         x = "Contract", y = "Churn probability")

  yrep_df <- as.data.frame(models$hierarchical$yrep_mat)
  names(yrep_df) <- as.character(group_data$Contract)
  yrep_df <- yrep_df %>%
    pivot_longer(everything(), names_to = "Contract", values_to = "y_rep")
  obs_df <- group_data %>% mutate(Contract = as.character(Contract))

  ppc_contract <- ggplot(yrep_df, aes(y_rep)) +
    geom_histogram(bins = 30, fill = "lightblue", color = "white") +
    facet_wrap(~ Contract, scales = "free") +
    geom_vline(data = obs_df, aes(xintercept = y),
               color = "red", linetype = "dashed") +
    labs(title = "Posterior predictive churn counts by contract",
         x = "Simulated churn count", y = "Frequency")

  comparison <- tables$model_comparison %>%
    pivot_longer(c(y, expected_y_hier, expected_y_oneparam),
                 names_to = "type", values_to = "value") %>%
    mutate(type = factor(
      type, levels = c("y", "expected_y_hier", "expected_y_oneparam"),
      labels = c("Observed", "Hierarchical model", "One-parameter model")
    ))

  plot_compare_models <- ggplot(comparison, aes(Contract, value, fill = type)) +
    geom_col(position = "dodge") +
    scale_fill_manual(values = c(
      "Observed" = "lightblue4", "Hierarchical model" = "lightblue3",
      "One-parameter model" = "lightblue1"
    )) +
    labs(title = "Observed vs model-implied churn counts",
         x = "Contract", y = "Churn count", fill = "Type")

  list(churn_bar = plot_churn_bar, contract_rate = plot_contract_rate,
       mc_posterior = plot_mc_posterior, ppc_total = ppc_total_hist,
       theta_density = plot_theta_contract_density,
       theta_interval = plot_theta_contract_interval,
       ppc_contract = ppc_contract, comparison_models = plot_compare_models)
}
