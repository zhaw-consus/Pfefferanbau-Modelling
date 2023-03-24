library(terra)
library(tidyverse)
library(httpgd)
library(tmap)
library(tictoc)
library(glue)
# httpgd::hgd()


clean_name <- function(inp){
    inp |>
        str_remove_all("\\.") |>
        str_replace_all(" ","-")
}

suitability <- function(characteristic_df, characteristic, filename = NULL){
    # browser()
    df_filter <- characteristic_df[characteristic_df$Characteristic == characteristic,]

    stopifnot(file.exists(df_filter$file))

    reclass_table <- df_filter$reclass_table[[1]]

    if(!is.na(df_filter$layer)){
        raster_obj <- rast(df_filter$file, lyrs = df_filter$layer)
    } else{
        raster_obj <- rast(df_filter$file)
    }

    if(characteristic == "slope"){
        slope <- terrain(raster_obj, "slope", unit =  "radians")
        raster_obj <- tan(slope) * 100
    } else if(characteristic == "pH"){
        raster_obj <- raster_obj/10
    }

    raster_out <- classify(
        raster_obj,
        reclass_table,
        include.lowest = TRUE, #only affects "min monthly percipitation"
        filename = filename
        )
    names(raster_out) <- characteristic
    raster_out
}

resolution_path <- tribble(
    ~resolution, ~path,
    "10m", "10min"
)

data_10min <- read_csv("data-csvs/data-10min.csv") |>
    mutate(resolution = str_remove(resolution, "1_")) |>
    # keep naming consistent with worldclim website
    rename(GCM = model, SSP = szenario, period = time) |>
    left_join(resolution_path, by = "resolution") |>
    select(-urls)


historic_files <- list.files("data-raw/10min-historic-worldclim","\\.tif$",full.names = TRUE)


historic_df <- tibble(
    filename = basename(historic_files),
    path = dirname(historic_files),
) |>
    separate(filename, c("version", "resolution","var1","var2"), sep = "_", remove = FALSE) |>
    mutate(var2 = str_remove(var2, ".tif"))

historic_df_bio <- historic_df |>
    filter(var1 == "bio")  |>
    # the following lines adapt the historic naming to the 
    # naming of the future szenario data
    rename(variable = var1, layer = var2) |>
    mutate(
        variable = "bioc",
        layer = as.integer(layer)
        )

historic_df_monthly <- historic_df |>
    filter(var1 != "bio") |>
    rename(variable = var1, month = var2,)


# "GFDL-ESM4" is missing the some time szenarios or time ranges
data_10min <- data_10min |>
    filter(GCM != "GFDL-ESM4")

crop_characteristics <- read_csv("data-csvs/Cropdb.Input_Crop_Characteristics.csv")

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
    ~Class_int,~Class,
      1L,"S1",
      2L,"S2",
      3L,"S3",
      4L, "N",
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
    "mean annual temperature", "bioc", 1L,
    "annual precipitation", "bioc", 12L,
    "min. monthly precipitation", "bioc", 14L,
    "mean max. temp of the warmest month", "bioc", 5L,
    "mean min. temp of the coldest month", "bioc", 6L,
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


data_10min_nested$characteristic_df[[1]]


characteristic_df_historic <- crop_characteristics_nested |>
    left_join(transmute(historic_df_bio, variable, layer, file = file.path(path, filename)), by = c("variable", "layer")) |>
    mutate(layer = NA) # see [1]

# [1]: Very Ugly. But for the future data, the bioclim variables are stored as layers in a single file
# for the historic data, the variables are stored in individual files. If I pass a layer number to my 
# suitability function, it will try to load in a specific layer / band from the input file. This is
# not necessary for the historic data.


characteristics <- c(
    "min. monthly precipitation",
    "annual precipitation",
    "mean annual temperature",
    "mean max. temp of the warmest month",
    "mean min. temp of the coldest month"
)

suitability_all <- function(
    characteristic_df,
    method = "individual",
    characteristics = c(
        "min. monthly precipitation",
        "annual precipitation",
        "mean annual temperature",
        "mean max. temp of the warmest month",
        "mean min. temp of the coldest month"
    ),
    filename = NULL
    ){
    # browser()
    raster_stack <- map(characteristics, \(x){
        suitability(characteristic_df, x)
    }) |>
        rast()

    if(method == "individual"){
        # do nothing
    } else if(method == "max_only"){
        raster_stack <- max(raster_stack)
    } else if(method == "both"){
        add(raster_stack) <- max(raster_stack)
    } else{
        errorCondition(paste("Method '",method, "'not implemented"))
    }

    if(!is.null(filename)){
        writeRaster(raster_stack, filename = filename)
    }

    raster_stack
}



time_independent_files <- tribble(
    ~Characteristic, ~file,
    "pH", "data-raw/phh20/phh2o_5-15cm_mean_10min.tif",
    "slope", "data-raw/wc2.1_10m_elev.tif"
)

crop_characteristics_nested2 <- crop_characteristics_nested  |>
    left_join(time_independent_files, by = "Characteristic")
