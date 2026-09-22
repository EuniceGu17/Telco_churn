source("R/data.R")

message("[prepare] Reading and validating raw data...")

telco <- read_telco("data/raw/Telco-Customer-Churn.csv")
groups <- summarize_contracts(telco)

dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)

saveRDS(telco, "data/processed/telco.rds")

message(
  "[prepare] Customers: ", nrow(telco),
  "; churns: ", sum(telco$Churn)
)

print(groups)
message("[prepare] Saved data/processed/telco.rds")
