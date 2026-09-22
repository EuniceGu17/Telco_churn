# Exact posterior for the overall churn probability.
beta_posterior <- function(y, n, a = 1, b = 1) {
  stopifnot(length(y) == 1, length(n) == 1,
            length(a) == 1, length(b) == 1,
            is.finite(y), is.finite(n), is.finite(a), is.finite(b),
            n >= 0, y >= 0, y <= n, n == floor(n), y == floor(y),
            a > 0, b > 0)
  post_a <- a + y
  post_b <- b + n - y
  ci <- qbeta(c(0.025, 0.975), post_a, post_b)

  data.frame(n = n, y = y, post_a = post_a, post_b = post_b,
             mean = post_a / (post_a + post_b),
             lower = ci[1], upper = ci[2])
}

fit_overall <- function(telco, seed = 321, n_sims = 20000) {
  n <- nrow(telco)
  y <- sum(telco$Churn)
  posterior <- beta_posterior(y, n)

  set.seed(seed)
  theta_samples <- rbeta(n_sims, posterior$post_a, posterior$post_b)

  # The original notebook resets the seed before the predictive simulation.
  set.seed(seed)
  y_rep_total <- rbinom(n_sims, size = n, prob = theta_samples)

  list(summary = posterior, theta_samples = theta_samples,
       y_rep_total = y_rep_total)
}

fit_hierarchical <- function(group_data, stan_file, seed = 321) {
  if (!file.exists(stan_file)) stop("Cannot find Stan model: ", stan_file)

  stan_data_hier <- list(
    J = nrow(group_data),
    n = as.integer(group_data$n),
    y = as.integer(group_data$y)
  )

  fit_hier <- rstan::stan(
    file = stan_file, data = stan_data_hier,
    iter = 2000, warmup = 1000, chains = 4,
    cores = 2, seed = seed, refresh = 500
  )

  set.seed(seed)
  posterior_draws <- rstan::extract(fit_hier)
  parameter_summary <- as.data.frame(
    summary(fit_hier, pars = c("alpha", "beta", "theta"))$summary
  )
  parameter_summary$parameter <- rownames(parameter_summary)
  rownames(parameter_summary) <- NULL

  sampler <- rstan::get_sampler_params(fit_hier, inc_warmup = FALSE)
  divergences <- sum(sapply(sampler, function(x) sum(x[, "divergent__"])))
  message("Divergent transitions: ", divergences)
  print(parameter_summary)
  if (divergences > 0 || anyNA(parameter_summary$Rhat) ||
      any(parameter_summary$Rhat > 1.01, na.rm = TRUE)) {
    warning("Check the sampling diagnostics before interpreting results.")
  }

  list(theta_draws = posterior_draws$theta,
       yrep_mat = posterior_draws$y_rep,
       parameter_summary = parameter_summary,
       divergences = divergences)
}
