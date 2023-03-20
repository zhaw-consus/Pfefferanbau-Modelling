library(terra)
library(tidyverse)
library(httpgd)
library(tmap)
library(tictoc)
# httpgd::hgd()


suitability <- function(characteristic_df, characteristic, others = NULL){
    browser()
    df_filter <- characteristic_df[characteristic_df$Characteristic == characteristic,]

    stopifnot(file.exists(df_filter$file))

    reclass_table <- df_filter$reclass_table[[1]]

    if(!is.na(df_filter$layer)){
        raster_obj <- rast(df_filter$file, lyrs = df_filter$layer)
    } else{
        raster_obj <- rast(df_filter$file)
    }

    if(characteristic == "min. monthly precipitation"){
        raster_obj <- min(raster_obj)
    } else if(characteristic == "slope"){
        slope <- terrain(raster_obj, "slope", unit =  "radians")
        raster_obj <- tan(slope)*100
    } else if(characteristic == "pH"){
        raster_obj <- raster_obj/10
    }

    # check if right = TRUE is the correct assumption
    raster_out <- classify(
        raster_obj, 
        reclass_table, 
        # include.lowest = TRUE only affects "min monthly percipitation"
        include.lowest = TRUE,
        others = others
        )
    
    names(raster_out) <- characteristic
    raster_out
}

resolution_path <- tribble(
    ~resolution, ~path,
    "10m", "10min"
)

data_10min <- read_csv("data-10min.csv") |>
    mutate(resolution = str_remove(resolution, "1_")) |>
    # keep naming consistent with worldclim website
    rename(GCM = model, SSP = szenario, period = time) |>
    left_join(resolution_path, by = "resolution") |>
    select(-urls)


# "GFDL-ESM4" is missing the some time szenarios or time ranges
data_10min <- data_10min |>
    filter(GCM != "GFDL-ESM4")

crop_characteristics <- read_csv("data-raw/Cropdb.Input_Crop_Characteristics.csv")

crop_characteristics_long <- crop_characteristics |>
    group_by(Crop, Characteristic) |>
    mutate(
        Characteristic_i = row_number()
    ) |>
    pivot_longer(
        cols = -c(Crop, Characteristic, Characteristic_i),
        names_to = c("Class", "Level", "Metric"),
        names_pattern = "(S\\d|N) (Top|Bottom) (Range|Value)"
    ) |>
    # it's safe to remove NA at this point, since for example the 
    # second mean annual temp does not have an S1 range
    na.omit() |> 
    pivot_wider(names_from = c(Level, Metric), values_from = value) |>
    mutate(across(ends_with("Value"), \(x){
        parse_number(x, locale = locale(grouping_mark = "'"))
    }))


class_int <- tribble(
    ~Class, ~Class_int,
    "S1", 1,
    "S2", 2,
    "S3", 3,
    "N", 4
)

crop_characteristics_long <- left_join(
    crop_characteristics_long,
    class_int,
    by = "Class"
    )

crop_characteristics_nested <- crop_characteristics_long |>
    group_by(Characteristic) |>
    select(Bottom_Value, Top_Value, Class_int) |>
    group_nest(.key = "reclass_table") 

characteristic_variable <- tribble(
    ~Characteristic, ~variable, ~layer,
    "mean annual temperature", "bioc", 1,
    "annual precipitation", "bioc", 12,
    "min. monthly precipitation", "prec", NA,
    "mean max. temp of the warmest month", "bioc", 5,
    "mean min. temp of the coldest month", "bioc", 6,
)

crop_characteristics_nested <- crop_characteristics_nested |>
    left_join(characteristic_variable, by = "Characteristic")

data_10min_nested <- data_10min |>
    group_by(resolution, GCM, SSP, period) |>
    transmute(variable, file = file.path(path,filename)) |>
    group_nest(.key = "characteristic_df") |>
    mutate(
        characteristic_df = map(characteristic_df, function(x){
        crop_characteristics_nested |>
            left_join(x, by = "variable")
    })
    )
    

characteristics <- c(
    "min. monthly precipitation",
    "annual precipitation",
    "mean annual temperature",
    "mean max. temp of the warmest month"
    # "mean min. temp of the coldest month",
)

suitability_all <- function(
    characteristic_df,
    max_only = TRUE,
    characteristics = c(
        "min. monthly precipitation",
        "annual precipitation",
        "mean annual temperature",
        "mean max. temp of the warmest month"
        # "mean min. temp of the coldest month",
    ),
    others = NULL
    ){
    raster_out <- map(characteristics, \(x) suitability(characteristic_df, x))  |> 
        rast()

    if(max_only){
        max(raster_out)
    } else {
        raster_out
    }
}

# calculate suitability for one characteristic, GCM, SSP and period
tic()
data_10min_nested |>
    filter(GCM == "ACCESS-CM2", SSP == "ssp585", period == "2081-2100") |>
    pull(characteristic_df) |>
    pluck(1) |>
    suitability("annual precipitation")
toc()



# calculate suitability for one GCM, SSP and period but for all characteristics
tic()
data_10min_nested |>
    filter(GCM == "ACCESS-CM2", SSP == "ssp585", period == "2081-2100") |>
    pull(characteristic_df) |>
    pluck(1) |>
    suitability_all()
toc()


# calculate suitability for all GCMs, SSPs and periods but one characteristic
# takes about 4 Minutes
map(data_10min_nested$characteristic_df, \(characteristic_df){
    suitability(characteristic_df, "annual precipitation")
}, .progress = TRUE)

# calculate suitability for all GCMs, SSPs and periods and ALL characteristics
# Takes about 15 Minutes
map(data_10min_nested$characteristic_df, \(characteristic_df){
    suitability_all(characteristic_df)
}, .progress = TRUE)


# Reimplement the following lines
# model_stack <- map(all_models_char, \(x){
#     model_it(data_10min, x, others = 4)
# }) |>
#     rast()

# model_modal <- modal(model_stack)
# plot(model_modal)

# uncertainty <- sum(model_modal == model_stack) / nlyr(model_stack)

# plot(uncertainty)

# writeRaster(model_modal, "data-modelled/model_modal.tif", overwrite = TRUE)
# writeRaster(uncertainty, "data-modelled/uncertainty.tif", overwrite = TRUE)

# model_access_cm2 <- model_it(data_10min, "ACCESS-CM2", others = 4)


# pH and slope are time independent, an therefore are best calculated once.

time_independent_files <- tribble(
    ~Characteristic, ~file,
    "pH", "data-raw/phh20/phh2o_5-15cm_mean_10min.tif",
    "slope", "data-raw/wc2.1_10m_elev.tif"
)

crop_characteristics_nested2 <- crop_characteristics_nested  |>
    left_join(time_independent_files, by = "Characteristic")


suitability(crop_characteristics_nested2, "pH")
suitability(crop_characteristics_nested2, "slope")





minmax(ph_h2o)
plot(ph_h2o)
