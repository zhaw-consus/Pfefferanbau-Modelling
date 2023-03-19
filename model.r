library(terra)
library(tidyverse)
library(httpgd)
library(tmap)

httpgd::hgd()

data_10min <- read_csv("data-10min.csv") |>
    mutate(resolution = str_remove(resolution, "1_"))



reclassify <- function(
    raster_input, 
    df, 
    characteristic, 
    char_col = "Characteristic", 
    from = "Bottom_Value", 
    to = "Top_Value", 
    becomes = "Class_int",
    include.lowest = TRUE,
    others = NA,
    set_name_to_characteristic = TRUE
    ){
    df_filter <- df[df[,char_col] == characteristic,]
    recl_table <- df_filter[,c(from,to, becomes)]
    reclassified <- classify(raster_input, recl_table, include.lowest = include.lowest, others = others)
    
    if(set_name_to_characteristic) names(reclassified) <- characteristic

    reclassified
}

crop_characteristics <- read_csv("data-raw/Cropdb.Input_Crop_Characteristics.csv")

crop_characteristics_long <- crop_characteristics |>
    group_by(Crop, Characteristic) |>
    mutate(
        Characteristic_i = row_number()
    )  |>
    pivot_longer(
        cols = -c(Crop, Characteristic, Characteristic_i),
        names_to = c("Class", "Level", "Metric"),
        names_pattern = "(S\\d|N) (Top|Bottom) (Range|Value)"
        ) |> 
    na.omit() |> # it's safe to remove NA at this point, since for example the second mean annual temp does not have an S1 range
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
    filter(Top_Value < Bottom_Value) |>
    select(-ends_with("Range"), -c(Characteristic_i, Class_int)) |>
    knitr::kable()





model_it <- function(df, model_sel = "ACCESS-CM2", szenario_sel = "ssp585", time_sel = "2061-2080", others = NA, final = TRUE){
    browser()
    data_filtered <- df |>
        filter(model == model_sel, szenario == szenario_sel, time == time_sel)

    bioc_filename <- file.path(
        "10min",
        data_filtered$filename[data_filtered$variable == "bioc"]
        )

    res <- list()
    # For 1 & 2
    bioc <- rast(bioc_filename)

    # 1. Mean annual temperature
    res[[1]] <- reclassify(
        bioc[[1]], 
        crop_characteristics_long, 
        "mean annual temperature", 
        others = others
        )
    
    # 2. Annual precipitation
    res[[2]] <- reclassify(
        bioc[[12]], 
        crop_characteristics_long, 
        "annual precipitation", 
        others = others
        )


    # 3. Min. monthly precipitation
    prec_filename <- file.path(
        "10min", 
        data_filtered$filename[data_filtered$variable == "prec"]
        )

    percipitation_monthly <- rast(prec_filename)

    res[[3]] <- percipitation_monthly |>
        min() |>
        reclassify(
            crop_characteristics_long, 
            "min. monthly precipitation", 
            others = others
            )

    # Mean Max. Temperature of Warmest Month → BIOC 5
    res[[4]] <- bioc[[5]] |>
        reclassify(
            crop_characteristics_long,
            "mean max. temp of the warmest month",
            others = others
        )
    tm_shape(res[[4]]) + tm_raster()

    # Mean Min. Temperature of Coldest Month
    # does not work, see https://github.zhaw.ch/CONSUS/Pfefferanbau-Modelling/issues/6
    # bioc[[6]] |>
    #     reclassify(
    #         crop_characteristics_long,
    #         "mean min. temp of the coldest month",
    #         others = others
    #     )

    elev <- rast("data-raw/wc2.1_10m_elev.tif")

    slope_rad <- terrain(elev, "slope", unit =  "radians")
    #  Percentage = [ Tan ( Degrees ) ] x 100
    # https://www.calcunation.com/calculator/degrees-to-percent.php

    slope_perc <- tan(slope_rad)*100

    res[[5]] <- slope_perc|>
        reclassify(
            crop_characteristics_long,
            "slope",
            others = others
        )

    # bring together

    pepper_stack <- rast(res)

    pepper_max <- max(pepper_stack)

    if(final){
        pepper_max
    } else{
        pepper_stack
    }
}



all_models_char <- unique(data_10min$model)
# "GFDL-ESM4" is missing the some time szenarios or time ranges
all_models_char <- all_models_char[all_models_char != "GFDL-ESM4"] 

model_stack <- map(all_models_char, \(x){
    model_it(data_10min, x, others = 4)}) |>
    rast()

model_modal <- modal(model_stack)
plot(model_modal)

uncertainty <- sum(model_modal == model_stack)/nlyr(model_stack)

plot(uncertainty)

writeRaster(model_modal, "data-modelled/model_modal.tif", overwrite = TRUE)
writeRaster(uncertainty, "data-modelled/uncertainty.tif", overwrite = TRUE)

model_access_cm2 <- model_it(data_10min, "ACCESS-CM2", others = 4)
model_access_cm2_partial <- model_it(data_10min, "ACCESS-CM2", others = 4, final = FALSE)

plot(model_access_cm2)
writeRaster(model_access_cm2, "data-modelled/access_cm2.tif",overwrite = TRUE)
writeRaster(model_access_cm2_partial, "data-modelled/access_cm2_stack.tif",overwrite = TRUE)
