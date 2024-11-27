#! /usr/bin/env Rscript

if (!requireNamespace("dplyr", quietly = TRUE)) {
    # Create a library directory in your home directory if it doesn't exist
    if (!dir.exists("~/R/library")) dir.create("~/R/library", recursive = TRUE)

    # Set the library path
    .libPaths("~/R/library")

    # Install the package to the specified library
    install.packages("dplyr", lib = "~/R/library", repos = "https://cran.r-project.org")

}

library(dplyr)

# Define the URL of the CSV file
url <- "https://people.sc.fsu.edu/~jburkardt/data/csv/airtravel.csv"

# Define the destination file path
destfile <- "airtravel.csv"

# Download the file
download.file(url, destfile, method = "curl")

# Read the CSV file
data <- read.csv(destfile)

# View the first few rows of the dataset
head(data)

# Calculate the average number of passengers for each month
data$Average <- rowMeans(data[, 2:4])

# Print the updated data with the average column
print(data)

