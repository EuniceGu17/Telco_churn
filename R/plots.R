# Convert a samples-by-groups matrix to a labeled long table.
draws_long <- function(x, groups, value_name) {
  data <- as.data.frame(x)
  names(data) <- as.character(groups$Contract)

  long <- tidyr::pivot_longer(
    data,
    cols = dplyr::everything(),
    names_to = "Contract",
    values_to = value_name
  )

  long$Contract <- factor(
    long$Contract,
    levels = as.character(groups$Contract)
  )

  long
}


# Build the eight designated figures without writing files.
make_plots <- function(models, tables) {
  groups <- models$groups
  overall <- models$overall
  hierarchical <- models$hierarchical
  contract_levels <- as.character(groups$Contract)

  counts <- data.frame(
    Churn = factor(c("No", "Yes"), levels = c("No", "Yes")),
    n = c(
      overall$summary$n - overall$summary$y,
      overall$summary$y
    )
  )

  rates <- groups
  rates$rate <- rates$y / rates$n

  theta <- data.frame(theta = overall$theta)
  total_rep <- data.frame(y_rep = overall$y_rep)

  group_theta <- draws_long(
    hierarchical$theta, groups, "theta"
  )

  group_rep <- draws_long(
    hierarchical$y_rep, groups, "y_rep"
  )

  intervals <- tables$contract_posterior
  intervals$Contract <- factor(
    intervals$Contract,
    levels = contract_levels
  )

  comparison <- tidyr::pivot_longer(
    tables$model_comparison,
    cols = c("observed", "hierarchical", "one_parameter"),
    names_to = "model",
    values_to = "count"
  )

  comparison$Contract <- factor(
    comparison$Contract,
    levels = contract_levels
  )

  comparison$model <- factor(
    comparison$model,
    levels = c("observed", "hierarchical", "one_parameter"),
    labels = c("Observed", "Hierarchical", "One-parameter")
  )

  plots <- list(
    churn_bar =
      ggplot2::ggplot(counts, ggplot2::aes(Churn, n)) +
      ggplot2::geom_col(fill = "lightblue") +
      ggplot2::geom_text(
        ggplot2::aes(label = n), vjust = -0.4
      ) +
      ggplot2::labs(
        title = "Overall churn counts",
        x = "Churn", y = "Count"
      ),

    contract_rate =
      ggplot2::ggplot(rates, ggplot2::aes(Contract, rate)) +
      ggplot2::geom_col(fill = "lightblue") +
      ggplot2::labs(
        title = "Churn rate by contract type",
        x = NULL, y = "Churn probability"
      ),

    mc_posterior =
      ggplot2::ggplot(theta, ggplot2::aes(theta)) +
      ggplot2::geom_histogram(
        binwidth = 0.001,
        fill = "lightblue", color = "white"
      ) +
      ggplot2::labs(
        title = "Posterior draws of overall churn probability",
        x = expression(theta), y = "Frequency"
      ),

    ppc_total =
      ggplot2::ggplot(total_rep, ggplot2::aes(y_rep)) +
      ggplot2::geom_histogram(
        bins = 30, fill = "lightblue", color = "white"
      ) +
      ggplot2::geom_vline(
        xintercept = overall$summary$y,
        color = "red", linetype = "dashed"
      ) +
      ggplot2::labs(
        title = "Posterior predictive total churn",
        x = "Simulated churn count", y = "Frequency"
      ),

    theta_density =
      ggplot2::ggplot(
        group_theta,
        ggplot2::aes(theta, fill = Contract)
      ) +
      ggplot2::geom_density(alpha = 0.4) +
      ggplot2::labs(
        title = "Posterior churn probabilities by contract",
        x = expression(theta[j]), y = "Density"
      ),

    theta_interval =
      ggplot2::ggplot(
        intervals,
        ggplot2::aes(Contract, mean)
      ) +
      ggplot2::geom_point(size = 3) +
      ggplot2::geom_errorbar(
        ggplot2::aes(ymin = lower, ymax = upper),
        width = 0.1
      ) +
      ggplot2::labs(
        title = "Posterior means and 95% credible intervals",
        x = NULL, y = "Churn probability"
      ),

    ppc_contract =
      ggplot2::ggplot(group_rep, ggplot2::aes(y_rep)) +
      ggplot2::geom_histogram(
        bins = 30, fill = "lightblue", color = "white"
      ) +
      ggplot2::facet_wrap(
        ~ Contract, scales = "free", nrow = 1
      ) +
      ggplot2::geom_vline(
        data = groups,
        ggplot2::aes(xintercept = y),
        color = "red", linetype = "dashed"
      ) +
      ggplot2::labs(
        title = "Posterior predictive churn by contract",
        x = "Simulated churn count", y = "Frequency"
      ),

    comparison_models =
      ggplot2::ggplot(
        comparison,
        ggplot2::aes(Contract, count, fill = model)
      ) +
      ggplot2::geom_col(position = "dodge") +
      ggplot2::scale_fill_manual(
        values = c("lightblue4", "lightblue3", "lightblue1")
      ) +
      ggplot2::labs(
        title = "Observed and model-implied churn counts",
        x = NULL, y = "Churn count", fill = "Model"
      )
  )

  lapply(
    plots,
    function(p) {
      p + ggplot2::theme_minimal(base_size = 11) +
        ggplot2::theme(legend.position = "bottom")
    }
  )
}
