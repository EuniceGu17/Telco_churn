# Read the columns used in the churn analysis.
read_telco <- function(path) {
  if (!file.exists(path)) stop("Cannot find data: ", path)

  telco_raw <- readr::read_csv(
    path, show_col_types = FALSE,
    col_types = readr::cols(.default = readr::col_character())
  )

  required <- c("customerID", "Churn", "Contract")
  if (!all(required %in% names(telco_raw))) {
    stop("Data must contain customerID, Churn and Contract.")
  }
  if (nrow(telco_raw) == 0) stop("The data file is empty.")
  if (anyNA(telco_raw$customerID) ||
      any(trimws(telco_raw$customerID) == "") ||
      anyDuplicated(telco_raw$customerID) > 0) {
    stop("Customer IDs must be present and unique.")
  }
  if (!all(telco_raw$Churn %in% c("Yes", "No"))) {
    stop("Churn must be Yes or No.")
  }

  contracts <- c("Month-to-month", "One year", "Two year")
  if (!all(telco_raw$Contract %in% contracts) ||
      !all(contracts %in% telco_raw$Contract)) {
    stop("Check the three contract categories.")
  }

  # TotalCharges is not used, so its missing values do not remove customers.
  telco <- telco_raw %>%
    select(customerID, Contract, Churn) %>%
    mutate(
      Churn = if_else(Churn == "Yes", 1L, 0L),
      Contract = factor(Contract, levels = contracts)
    )
  telco
}

summarize_contracts <- function(telco) {
  telco %>%
    group_by(Contract) %>%
    summarise(n = n(), y = sum(Churn), .groups = "drop") %>%
    arrange(Contract)
}
