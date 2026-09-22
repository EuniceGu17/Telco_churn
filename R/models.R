# Calculate a conjugate Beta posterior and equal-tailed interval.
beta_posterior <- function(y, n, a = 1, b = 1) {
  values <- list(y, n, a, b)

  valid_scalar <- vapply(
    values,
    function(x) {
      is.numeric(x) && length(x) == 1L &&
        !is.na(x) && is.finite(x)
    },
    logical(1)
  )

  if (!all(valid_scalar)) {
    stop("y, n, a and b must be finite numeric scalars.")
  }

  if (n < 0 || y < 0 || y > n ||
      n != floor(n) || y != floor(y) ||
      a <= 0 || b <= 0) {
    stop("Invalid binomial counts or Beta prior parameters.")
  }

  post_a <- a + y
  post_b <- b + n - y
  interval <- stats::qbeta(c(0.025, 0.975), post_a, post_b)

  data.frame(
    n = n,
    y = y,
    post_a = post_a,
    post_b = post_b,
    mean = post_a / (post_a + post_b),
    lower = interval[1],
    upper = interval[2]
  )
}


# Draw from the overall posterior and posterior predictive distribution.
fit_overall <- function(data, seed = 321L, n_sims = 20000L) {
  n <- nrow(data)
  y <- sum(data$Churn)
  summary <- beta_posterior(y, n)

  set.seed(seed)
  theta <- stats::rbeta(
    n_sims,
    summary$post_a,
    summary$post_b
  )

  # Preserve the original notebook's separate RNG reset for PPC.
  set.seed(seed)
  y_rep <- stats::rbinom(n_sims, size = n, prob = theta)

  list(summary = summary, theta = theta, y_rep = y_rep)
}


# Fit the hierarchical model and retain portable draws and diagnostics.
fit_hierarchical <- function(
    groups,
    stan_file,
    seed = 321L,
    chains = 4L,
    iter = 2000L,
    warmup = 1000L) {

  if (!file.exists(stan_file)) {
    stop("Stan model not found: ", stan_file)
  }

  if (any(groups$y < 0 | groups$y > groups$n)) {
    stop("Group churn counts must lie between zero and group size.")
  }

  stan_data <- list(
    J = nrow(groups),
    n = as.integer(groups$n),
    y = as.integer(groups$y)
  )

  detected <- parallel::detectCores()
  cores <- if (is.na(detected)) 1L else min(chains, detected)

  fit <- rstan::stan(
    file = stan_file,
    data = stan_data,
    seed = seed,
    chains = chains,
    cores = cores,
    iter = iter,
    warmup = warmup,
    refresh = 500
  )

  set.seed(seed)
  draws <- rstan::extract(
    fit,
    pars = c("alpha", "beta", "theta", "y_rep")
  )

  parameter_summary <- as.data.frame(
    summary(fit, pars = c("alpha", "beta", "theta"))$summary
  )

  parameter_summary <- cbind(
    parameter = rownames(parameter_summary),
    parameter_summary
  )
  rownames(parameter_summary) <- NULL

  sampler <- rstan::get_sampler_params(
    fit,
    inc_warmup = FALSE
  )

  divergences <- sum(vapply(
    sampler,
    function(x) sum(x[, "divergent__"]),
    numeric(1)
  ))

  max_rhat <- max(parameter_summary$Rhat, na.rm = TRUE)
  min_neff <- min(parameter_summary$n_eff, na.rm = TRUE)

  diagnostics <- data.frame(
    divergences = divergences,
    max_rhat = max_rhat,
    min_n_eff = min_neff
  )

  if (divergences > 0 ||
      any(!is.finite(parameter_summary$Rhat)) ||
      max_rhat > 1.01) {
    warning("Inspect MCMC diagnostics before interpreting the results.")
  }

  list(
    theta = draws$theta,
    y_rep = draws$y_rep,
    alpha = draws$alpha,
    beta = draws$beta,
    parameter_summary = parameter_summary,
    diagnostics = diagnostics
  )
}
