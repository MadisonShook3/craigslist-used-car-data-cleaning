
# Craigslist Used Car Data Cleaning Project
# Step 1: Load a sample of the original dataset

library(data.table)

# Read only the first 100,000 rows
vehicles <- fread("vehicles.csv", nrows = 100000)

# Check the dataset dimensions
print(dim(vehicles))

# Display column names
print(names(vehicles))

# Count missing values in each column
print(sort(colSums(is.na(vehicles)), decreasing = TRUE))


# Step 2: Investigate data quality problems

# Check for duplicate IDs
print(sum(duplicated(vehicles$id)))

# Check vehicle prices
print(summary(vehicles$price))

# Count listings with zero or negative prices
print(sum(vehicles$price <= 0, na.rm = TRUE))

# Count listings with prices over $100,000
print(sum(vehicles$price > 100000, na.rm = TRUE))

# Check vehicle mileage
print(summary(vehicles$odometer))

# Count listings with negative mileage
print(sum(vehicles$odometer < 0, na.rm = TRUE))

# Count listings with mileage over 500,000
print(sum(vehicles$odometer > 500000, na.rm = TRUE))

# Check missing or blank manufacturer values
print(table(vehicles$manufacturer, useNA = "ifany"))

# Check vehicle condition categories
print(table(vehicles$condition, useNA = "ifany"))

# Check missing or blank text fields
text_columns <- names(vehicles)[sapply(vehicles, is.character)]

blank_counts <- sapply(vehicles[, ..text_columns], function(x) {
  sum(trimws(x) == "", na.rm = TRUE)
})

print(sort(blank_counts, decreasing = TRUE))


# Step 3: Clean missing values and duplicate records

# Create a copy to preserve the original data
cleaned <- copy(vehicles)

# Convert blank text values to NA
text_columns <- names(cleaned)[sapply(cleaned, is.character)]

for (col in text_columns) {
  cleaned[[col]] <- trimws(cleaned[[col]])
  cleaned[[col]][cleaned[[col]] == ""] <- NA
}

# Remove the completely empty county column
cleaned[, county := NULL]

# Remove duplicate listing IDs, keeping the first
cleaned <- cleaned[!duplicated(id)]

# Check missing values after cleaning
print(sort(colSums(is.na(cleaned)), decreasing = TRUE))

# Check dimensions after cleaning
print(dim(cleaned))



# Step 4: Clean vehicle prices and mileage

# Record questionable prices before cleaning
cleaned[, price_flag := fifelse(
  price <= 0, "Invalid price",
  fifelse(price > 100000, "High price", "Valid price")
)]

# Replace zero and negative prices with NA
cleaned[price <= 0, price := bit64::as.integer64(NA)]

# Record questionable mileage values
cleaned[, mileage_flag := fifelse(
  is.na(odometer), "Missing mileage",
  fifelse(odometer > 500000, "High mileage",
          "Valid mileage")
)]

# Replace extreme mileage with NA
cleaned[!is.na(odometer) & odometer > 500000,
        odometer := NA_real_]

# Check price flags
print(table(cleaned$price_flag))

# Check mileage flags
print(table(cleaned$mileage_flag))

# Check cleaned price summary
print(summary(cleaned$price))

# Check cleaned mileage summary
print(summary(cleaned$odometer))

# Check dimensions
print(dim(cleaned))


# Step 5: Standardize vehicle information

# Standardize capitalization
cleaned[, manufacturer := tolower(manufacturer)]
cleaned[, condition := tolower(condition)]
cleaned[, transmission := tolower(transmission)]
cleaned[, fuel := tolower(fuel)]
cleaned[, type := tolower(type)]

# Convert posting dates into R date format
cleaned[, posting_date := as.Date(
  substr(posting_date, 1, 10),
  format = "%Y-%m-%d"
)]

# Check manufacturer categories
print(sort(table(cleaned$manufacturer), decreasing = TRUE))

# Check condition categories
print(table(cleaned$condition, useNA = "ifany"))

# Check transmission categories
print(table(cleaned$transmission, useNA = "ifany"))

# Check date range
print(range(cleaned$posting_date, na.rm = TRUE))

# Check final dimensions
print(dim(cleaned))


# Step 6: Create an analysis-ready dataset

# Keep records with prices between $500 and $100,000
# This is an analysis filter, not a claim that all
# prices outside this range are incorrect.
analysis_cars <- cleaned[
  !is.na(price) & price >= 500 & price <= 100000
]

# Keep records with known manufacturers and years
analysis_cars <- analysis_cars[
  !is.na(manufacturer) & !is.na(year)
]

# Compare the original and analysis-ready datasets
print(dim(cleaned))
print(dim(analysis_cars))

# Compare price summaries
print(summary(cleaned$price))
print(summary(analysis_cars$price))

# Count listings by manufacturer
print(sort(table(analysis_cars$manufacturer),
           decreasing = TRUE))


# Step 7: Create a vehicle price visualization

# Find the 10 manufacturers with the most listings
top_manufacturers <- names(sort(
  table(analysis_cars$manufacturer),
  decreasing = TRUE
))[1:10]

# Calculate median price for each manufacturer
price_summary <- analysis_cars[
  manufacturer %in% top_manufacturers,
  .(
    median_price = median(as.numeric(price), na.rm = TRUE),
    listing_count = .N
  ),
  by = manufacturer
]

# Sort manufacturers by median price
setorder(price_summary, median_price)

# Display summary table
print(price_summary)

# Save the plot as a PNG file
png("median_price_by_manufacturer.png",
    width = 1100, height = 700)

barplot(
  price_summary$median_price,
  names.arg = price_summary$manufacturer,
  horiz = TRUE,
  las = 1,
  col = "steelblue",
  main = "Median Used Car Listing Price by Manufacturer",
  xlab = "Median Listing Price ($)",
  cex.names = 0.9
)

dev.off()

# Confirm the plot was saved
print(file.exists("median_price_by_manufacturer.png"))


# Step 8: Create a before-and-after data quality table

quality_summary <- data.table(
  Issue = c(
    "Blank manufacturer values",
    "Blank condition values",
    "Invalid prices (zero or negative)",
    "Extreme mileage values (>500,000)",
    "Completely empty columns",
    "Duplicate listing IDs"
  ),
  Before = c(
    sum(trimws(vehicles$manufacturer) == "", na.rm = TRUE),
    sum(trimws(vehicles$condition) == "", na.rm = TRUE),
    sum(vehicles$price <= 0, na.rm = TRUE),
    sum(vehicles$odometer > 500000, na.rm = TRUE),
    sum(colSums(is.na(vehicles)) == nrow(vehicles)),
    sum(duplicated(vehicles$id))
  ),
  After = c(
    sum(!is.na(cleaned$manufacturer) &
          cleaned$manufacturer == ""),
    sum(!is.na(cleaned$condition) &
          cleaned$condition == ""),
    sum(cleaned$price <= 0, na.rm = TRUE),
    sum(cleaned$odometer > 500000, na.rm = TRUE),
    sum(colSums(is.na(cleaned)) == nrow(cleaned)),
    sum(duplicated(cleaned$id))
  )
)

# Display the comparison table
print(quality_summary)

# Save the comparison table
fwrite(quality_summary, "data_quality_comparison.csv")

# Confirm the file was saved
print(file.exists("data_quality_comparison.csv"))


# Step 9: Export cleaned datasets

# Save the full cleaned 100,000-row sample locally
fwrite(cleaned, "cleaned_vehicles.csv")

# Select useful columns for future visualizations
dashboard_data <- analysis_cars[, .(
  id,
  price = as.numeric(price),
  year,
  manufacturer,
  model,
  condition,
  fuel,
  odometer,
  transmission,
  drive,
  type,
  state,
  posting_date
)]

# Save a compact dataset for the Shiny dashboard
fwrite(dashboard_data, "dashboard_vehicles.csv")

# Confirm both files were saved
print(file.exists("cleaned_vehicles.csv"))
print(file.exists("dashboard_vehicles.csv"))

# Check dashboard dimensions and file sizes
print(dim(dashboard_data))
print(file.info(c(
  "cleaned_vehicles.csv",
  "dashboard_vehicles.csv"
))$size / 1024^2)
