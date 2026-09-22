testthat::test_that("Beta posterior matches a hand-calculated example", {
  result <- beta_posterior(y = 3, n = 10, a = 1, b = 1)

  testthat::expect_equal(result$post_a, 4)
  testthat::expect_equal(result$post_b, 8)
  testthat::expect_equal(result$mean, 1 / 3)
  testthat::expect_lt(result$lower, result$mean)
  testthat::expect_gt(result$upper, result$mean)
})

testthat::test_that("invalid counts are rejected", {
  testthat::expect_error(beta_posterior(y = 11, n = 10))
})
