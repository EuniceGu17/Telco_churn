telco <- read_telco("data/raw/Telco-Customer-Churn.csv")
group_data <- summarize_contracts(telco)
stopifnot(nrow(telco) == 7043, sum(telco$Churn) == 1869,
          all(group_data$n == c(3875, 1473, 1695)),
          all(group_data$y == c(1655, 166, 48)))

# An invalid churn label must cause an error rather than become zero.
bad_data <- data.frame(
  customerID = c("a", "b", "c"), Churn = c("Yes", "Unknown", "No"),
  Contract = c("Month-to-month", "One year", "Two year")
)
temp_file <- tempfile(fileext = ".csv")
readr::write_csv(bad_data, temp_file)
result <- try(read_telco(temp_file), silent = TRUE)
unlink(temp_file)
stopifnot(inherits(result, "try-error"))
cat("Data validation passed.\n")
