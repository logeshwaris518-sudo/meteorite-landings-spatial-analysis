# Meteorite Landings — Spatial Analysis

A spatial and temporal analysis of ~45,000 meteorite landings recorded worldwide, built in R. The project investigates distribution patterns, discovery bias, and classification trends across continents, backed by formal spatial statistics — not just visualizations.

## Demo

(screen recording of the interactive dashboard goes here)

(output screenshots — Ripley's K plot, KDE map, Moran's I console output — go here)

## Overview

Meteorite landing data carries a well-known problem: where a meteorite is recorded isn't purely about where meteorites actually fall — it's also about where people are around to find them. This project quantifies that bias using real spatial statistics, then visualizes the results through both static analysis and a live interactive dashboard.

## Dataset

- Source: NASA Open Data Portal — Meteorite Landings
  https://data.nasa.gov/docs/legacy/meteorite_landings/Meteorite_Landings.csv
- Size: ~45,000 records
- Key fields used: name, mass, classification (recclass), fall type (Fell vs Found), year, latitude/longitude

## Tech Stack

| Purpose | Package |
| --- | --- |
| Data wrangling | dplyr, tidyr |
| Spatial data handling | sf |
| Point pattern analysis | spatstat |
| Spatial autocorrelation | spdep |
| Continent boundaries | rnaturalearth, rnaturalearthdata |
| Static visualization | ggplot2 |
| Interactive maps | leaflet |
| Interactive dashboard | shiny |

## Analysis Pipeline

### 1. Data Cleaning
- Coordinates of exactly 0°N, 0°E are treated as missing data (a known NASA dataset quirk), not real locations, and removed.
- Records with invalid mass, latitude/longitude, or year values are filtered out.
- Years are restricted to the dataset's own valid range.

### 2. Continent Assignment
Each meteorite's coordinates are spatially joined against world country boundaries (via rnaturalearth) to tag every record with its continent.

### 3. Point Pattern Analysis — Ripley's K Function
Tests whether meteorite landings are more clustered than pure random chance would predict. If the observed K-function line sits above the theoretical random line, it's statistical evidence of clustering — not just a visual impression from a map.

### 4. Kernel Density Estimation (KDE)
Produces a smooth density surface showing where landings concentrate most heavily, independent of any single administrative boundary.

### 5. Spatial Autocorrelation — Moran's I
The study area is divided into a grid, and Moran's I tests whether nearby grid cells have statistically similar landing counts — a formal test for "is there a real spatial pattern here, or is this just noise?"

### 6. Temporal Trends
Landings are plotted by year, split by Fell (witnessed falling) vs Found (discovered after the fact), to see how recording patterns have changed over time.

### 7. Recovery Bias Analysis
For each continent, a found_ratio is calculated: Found / (Fell + Found). A high found_ratio combined with low population density (e.g. Antarctica, deserts) is the signature of discovery bias — meteorites that were always there, just rarely witnessed falling.

### 8. Classification Distribution
The top meteorite classes are broken down by continent, to see whether certain classification types are over- or under-represented in certain regions.

### 9. Interactive Map
A leaflet map plots every cleaned record, color-coded by Fell/Found, sized by mass, with popups showing name, class, mass, and year.

### 10. Interactive Shiny Dashboard
A live dashboard layered on top of the same analysis, with:
- Continent filter — narrow the map and charts to one continent or view all
- Year range slider — filter by any time period
- Fell/Found toggle — isolate witnessed falls vs. later discoveries
- Three live tabs: Interactive Map, Bias Ratio by Continent, Kernel Density

## Key Findings

(add your interpreted results here once finalized — e.g. Moran's I statistic and p-value, which continents show the strongest found_ratio bias, and what the Ripley's K plot indicates about clustering)

## How to Run

1. Download the dataset from the NASA link above and place it in the project folder.
2. Install required packages:

install.packages(c("dplyr", "tidyr", "sf", "leaflet", "ggplot2",
                    "spatstat", "spdep", "rnaturalearth",
                    "rnaturalearthdata", "shiny"))

3. Run the main analysis script (Code.r) to generate the statistical plots and results.
4. Run the dashboard script to launch the interactive Shiny app:

shiny::runApp("Meteorite_landings_code.R")

## Project Structure

Code.r                        — Main analysis: cleaning, Ripley's K, KDE, Moran's I,
                                 temporal trends, bias analysis, leaflet map
Meteorite_landings_code.R     — Interactive Shiny dashboard
Meteorite_Landings.csv        — Dataset (NASA Open Data)

## Author

Logeshwari S
