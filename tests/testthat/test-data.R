testthat::test_that("raw data match the original analysis counts", {
  data <- read_telco("data/raw/Telco-Customer-Churn.csv")
  groups <- summarize_contracts(data)

  testthat::expect_equal(nrow(data), 7043L)
  testthat::expect_equal(sum(data$Churn), 1869L)
  testthat::expect_equal(groups$n, c(3875L, 1473L, 1695L))
  testthat::expect_equal(groups$y, c(1655L, 166L, 48L))
})

testthat::test_that("invalid churn values are rejected", {
  bad <- data.frame(
    customerID = c("a", "b", "c"),
    Churn = c("Yes", "Unknown", "No"),
    Contract = c("Month-to-month", "One year", "Two year")
  )

  testthat::expect_error(
    validate_telco(bad),
    "Churn"
  )
})

testthat::test_that("duplicate customer IDs are rejected", {
  bad <- data.frame(
    customerID = c("a", "a", "c"),
    Churn = c("Yes", "No", "No"),
    Contract = c("Month-to-month", "One year", "Two year")
  )

  testthat::expect_error(
    validate_telco(bad),
    "unique"
  )
})
