testthat::test_that("ties cannot produce a probability above one", {
  testthat::expect_equal(
    ppc_two_sided(rep(5, 100), observed = 5),
    1
  )
})

testthat::test_that("a one-sided extreme has zero two-sided tail probability", {
  testthat::expect_equal(
    ppc_two_sided(c(1, 2, 3), observed = 10),
    0
  )
})

testthat::test_that("non-finite draws are rejected", {
  testthat::expect_error(
    ppc_two_sided(c(1, NA), observed = 1)
  )
})
