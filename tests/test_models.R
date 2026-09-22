# A Beta(1, 1) prior and 3 successes out of 10 give Beta(4, 8).
posterior <- beta_posterior(y = 3, n = 10)
stopifnot(posterior$post_a == 4, posterior$post_b == 8,
          abs(posterior$mean - 1 / 3) < 1e-12,
          posterior$lower < posterior$mean,
          posterior$upper > posterior$mean)
stopifnot(inherits(try(beta_posterior(11, 10), silent = TRUE), "try-error"))
cat("Posterior calculation passed.\n")
