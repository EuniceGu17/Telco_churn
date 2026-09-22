library(dplyr)
source("R/data.R")

message("Reading and checking Telco data...")
telco <- read_telco("data/raw/Telco-Customer-Churn.csv")
group_data <- summarize_contracts(telco)

dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)
saveRDS(telco, "data/processed/telco.rds")

cat("Sample size:", nrow(telco), "\nNumber of churns:", sum(telco$Churn), "\n")
print(group_data)
