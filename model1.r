library(terra)
library(tidyverse)
library(tmap)
# library(DBI)

reclassify <- function(raster_input, df, characteristic, char_col = "Characteristic", from = "Bottom_Value", to = "Top_Value", becomes = "Class_int"){

    df_filter <- df[df[,char_col] == characteristic,]
    recl_table <- df_filter[,c(from,to, becomes)]

    classify(raster_input, recl_table, include.lowest = TRUE, others = NA)

}


# con <- dbConnect(RPostgres::Postgres(),
#                  dbname = "astra",
#                  host = "svma-s-01348.zhaw.ch",
#                  port = 5432,
#                  user = "",
#                  password = "")


crop_characteristics <- read_csv("data-raw/Cropdb.Input_Crop_Characteristics.csv") |>
    na.omit()
crop_characteristics_long <- crop_characteristics |>
    # select(-ends_with("Value")) |>
    pivot_longer(
        cols = -c(Crop, Characteristic),
        names_to = c("Class", "Level", "Metric"),
        names_pattern = "(S\\d|N) (Top|Bottom) (Range|Value)"
        ) |>
    # filter(Metric == "Value") |>
    pivot_wider(names_from = c(Level, Metric), values_from = value)  |>
    mutate(across(ends_with("Value"), \(x)parse_number(x, locale = locale(grouping_mark = "'"))))


class_int <- tribble(
    ~Class, ~Class_int,
    "S1", 1,
    "S2", 2,
    "S3", 3,
    "N", 4
)

crop_characteristics_long <- left_join(crop_characteristics_long, class_int, by = "Class")

# I dont understand the "_Range" Columns. How should I interpret them?
# Quality check: Is top always larger than bottom?
crop_characteristics_long |>
    filter(Top_Value < Bottom_Value)


# Carmen hat folgende Parameter in der CONSUS DB erfasst:
# 1. Mean annual temperature
# 2. Annual precipitation
# 3. Min. monthly precipitation
# 4. Length of dry season
# 5. Slope
# 6. pH
# Du kannst also mal mit den ersten drei Parametern beginnen. 
# Die ‘mean annual temperature’ (BIO1) und die ‘annual precipitation’ (BIO12) 
# befinden sich auf WorldClim in den bioclimatic variables. Für die 
# ‘min. monthly precipitation’ bräuchten wir die Variable ‘pr’ (= monthly total 
# precipitation), d.h. die Niederschlagsmenge jedes Monats.




# For 1 & 2
bioc <- rast("data-raw/wc2.1_10m_bioc_ACCESS-CM2_ssp585_2061-2080.tif")

# 1. Mean annual temperature


mean_annual_temp <- bioc[[1]]


mean_annual_temp_relc <- reclassify(mean_annual_temp, crop_characteristics_long, "mean annual temperature")



# 2. Annual precipitation
annual_percipitation <- bioc[[12]]


annual_precipitation_recl <- reclassify(annual_percipitation, crop_characteristics_long, "annual precipitation")


# 3. Min. monthly precipitation
percipitation_monthly <- rast("data-raw/wc2.1_10m_prec_ACCESS-CM2_ssp585_2061-2080.tif")
min_percipitation_monthly <- min(percipitation_monthly)


min_percipitation_monthly_recl <- reclassify(min_percipitation_monthly, crop_characteristics_long, "min. monthly precipitation")


# bring together

pepper_max <- max(mean_annual_temp_relc, annual_precipitation_recl, min_percipitation_monthly_recl)

plot(pepper_max)
