# craigslist-used-car-data-cleaning
Cleaning and analyzing messy Craigslist used-car listing data using R.

## Project Overview

This project demonstrates data cleaning and preparation using R. I worked with Craigslist used car listings to identify missing values, investigate questionable data, standardize variables, and prepare a dataset for visualization.

The goal was to turn raw vehicle listings into a more consistent dataset that could be used for exploratory analysis and a future interactive Shiny dashboard.

## Dataset

Source: [Craigslist Cars and Trucks Data — Kaggle](https://www.kaggle.com/datasets/austinreese/craigslist-carstrucks-data)

The original dataset contains used-vehicle listings from Craigslist. Because the full CSV file is very large, I used the first 100,000 records for this project.
The raw dataset is not included in this repository due to its file size.

## Data Cleaning Process

All cleaning steps were completed in cleaning.R using R and the data.table package.

### 1. Initial Data Exploration

I examined the dataset's dimensions, column names, missing values, duplicate IDs, vehicle prices, mileage, and categorical variables.

Some important findings included:

- 4,420 blank manufacturer values
- 38,289 blank condition values
- 8,328 listings with prices of zero or less
- 272 listings with mileage above 500,000
- One completely empty column (`county`)
- No duplicate listing IDs in the sample

### 2. Missing Values

I removed leading and trailing whitespace from text columns and converted empty strings into NA values.
This made missing information easier to identify and handle consistently.
I also removed the county column because every record in the sample was missing that value.

### 3. Duplicate Records

I checked for duplicate listing IDs and removed duplicates if any were present.
No duplicate IDs were found in the 100,000 row sample.

### 4. Price Cleaning

I identified 8,328 listings with prices of zero or less and replaced those values with NA.
I also created a price_flag column to distinguish invalid, high, and valid listing prices.
Unusually high prices were flagged rather than automatically deleted.

### 5. Mileage Cleaning

I identified 272 listings with mileage above 500,000 and replaced those values with NA.
A mileage_flag column records whether mileage was valid, missing, or unusually high.

### 6. Standardization

I standardized manufacturer names, vehicle conditions, fuel types, transmission types, and vehicle types to lowercase.
I also converted posting dates into R's Date format.

### 7. Analysis Dataset

I created a separate analysis-ready dataset using listings with:

- Prices between $500 and $100,000
- A known manufacturer
- A known vehicle year

These filters were chosen to examine typical used car asking prices. Listings outside this range were not necessarily incorrect.
The final analysis dataset contains 85,547 listings.

## Data Quality Results

| Issue | Before | After |
| Blank manufacturer strings | 4,420  | 0 |
| Blank condition strings    | 38,289 | 0 |
| Zero or negative prices    | 8,328  | 0 |
| Mileage above 500,000      | 272    | 0 |
| Completely empty columns   | 1      | 0 |
| Duplicate listing IDs      | 0      | 0 |

Blank strings and questionable numeric values were converted to missing values where appropriate. The table does not mean that all missing information was recovered.

## Visualization

I created a horizontal bar chart comparing median listing prices for the 10 manufacturers with the most listings in the analysis dataset.
[Median Used Car Listing Price by Manufacturer](median_price_by_manufacturer.png)

The median was used instead of the mean to reduce the influence of unusually expensive listings.
The filtered dataset had an average listing price of approximately **$19,269** and a median listing price of **$15,995**.
These comparisons describe asking prices, not actual vehicle sale prices, and do not control for differences in vehicle models, years, or mileage.

## Repository Files

- cleaning.R — R script containing the exploration, cleaning, filtering, and visualization steps.
- dashboard_vehicles.csv — Analysis-ready dataset containing 85,547 listings and 13 columns.
- data_quality_comparison.csv — Before-and-after data-quality summary.
- median_price_by_manufacturer.png — Visualization of median listing prices.
- .gitignore — Excludes large datasets and temporary R files.

## How to Reproduce

1. Download the original dataset from Kaggle.
2. Extract vehicles.csv into the same folder as cleaning.R.
3. Install the required R packages:

   ```r
   install.packages(c("data.table", "bit64"))
   ```

4. Run the cleaning script:

   ```r
   source("cleaning.R")
   ```

The script processes the first 100,000 records and generates the cleaned datasets, comparison table, and visualization.

## Limitations

This project uses the first 100,000 rows rather than a random sample of the full dataset, so the results may not represent all Craigslist vehicle listings.
The dataset also contains missing information and potentially inaccurate seller-entered values. Price and mileage thresholds were selected for the purposes of this analysis and should not be treated as universal rules.
