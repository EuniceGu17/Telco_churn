# Validate the raw fields needed.
validate_telco <- function(data) {
  required <- c("customerID", "Churn", "Contract")
  missing <- setdiff(required, names(data))

  if (length(missing) > 0L) {
    stop("Missing columns: ", paste(missing, collapse = ", "))
  }

  if (nrow(data) == 0L) {
    stop("Input data contain no rows.")
  }

  ids <- data$customerID

  if (anyNA(ids) || any(trimws(ids) == "")) {
    stop("customerID contains missing or empty values.")
  }

  if (anyDuplicated(ids) > 0L) {
    stop("customerID must be unique.")
  }

  if (anyNA(data$Churn) ||
      !all(data$Churn %in% c("Yes", "No"))) {
    stop("Churn must contain only Yes and No.")
  }

  allowed <- c("Month-to-month", "One year", "Two year")

  if (anyNA(data$Contract) ||
      !all(data$Contract %in% allowed)) {
    stop("Contract contains missing or unsupported values.")
  }

  if (!all(allowed %in% data$Contract)) {
    stop("All three contract groups must be present.")
  }

  invisible(TRUE)
}


# Read raw data and encode only the variables used.
read_telco <- function(path) {
  if (!file.exists(path)) {
    stop("Data file not found: ", path)
  }

  data <- readr::read_csv(
    path,
    col_types = readr::cols(.default = readr::col_character()),
    show_col_types = FALSE
  )

  validate_telco(data)

  data <- data[, c("customerID", "Contract", "Churn")]

  data$Churn <- as.integer(data$Churn == "Yes")
  data$Contract <- factor(
    data$Contract,
    levels = c("Month-to-month", "One year", "Two year")
  )

  data
}


# Summarize group sizes and churn counts in a fixed order.
summarize_contracts <- function(data) {
  data |>
    dplyr::group_by(Contract) |>
    dplyr::summarise(
      n = dplyr::n(),
      y = sum(Churn),
      .groups = "drop"
    ) |>
    dplyr::arrange(Contract)
}