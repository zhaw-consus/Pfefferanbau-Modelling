library(terra)
library(tidyverse)
library(httpgd)
library(tmap)
library(tictoc)
library(glue)
httpgd::hgd()


################################################################################
## Prepare spatial-temporal data (data that varies termporally) ################
################################################################################

chelsa_files <- list.files("data-chelsa", "\\.tif$",full.names = TRUE)


chelsa_df <- tibble(
    filename = basename(chelsa_files),
    path = dirname(chelsa_files),
) |>
    extract(
        filename, 
        c("variable","period",NA,"gcm",NA,"ssp","version"),
        "CHELSA_(\\w+)_(\\d{4}-\\d{4})(_([a-z,0-9,-]+))?(_(\\w+))?_(V\\.\\d\\.\\d).tif",
        remove = FALSE
        )


chelsa_df <- chelsa_df |>
#wont use NA, since I might run a bash script on the resulting csv
    mutate(
        gcm = ifelse(period == "1981-2010", "not-applicable", gcm), 
        ssp = ifelse(period == "1981-2010", "not-applicable", ssp),
        type = ifelse(period == "1981-2010", "historic", "predicted")
    ) |>
    # removes hurs_*
    filter(startsWith(variable,"bio"))

chelsa_df2 <- chelsa_df |>
    group_by(gcm, ssp, period) |>
    transmute(variable, file = file.path(path,filename)) |>
    ungroup()


################################################################################
## Prepare Crop Characteristics data  ##########################################
################################################################################


crop_characteristics <- read_csv("data-csvs/Cropdb.Input_Crop_Characteristics.csv")


crop_characteristics <- crop_characteristics |>
# see https://github.zhaw.ch/CONSUS/Pfefferanbau-Modelling/issues/3
    filter(Characteristic != "min. monthly precipitation")  |>
    # remove non-tempral data for now
    filter(!(Characteristic %in% c("pH", "slope","average annual relative humidity")))


crop_characteristics_long <- crop_characteristics |>
    select(-Crop) |>
    group_by(Characteristic) |>
    mutate(
        Characteristic_i = row_number(),
        Optimum = !is.na(`S1 Top Range`)
    ) |>
    pivot_longer(
        cols = -c(Characteristic, Characteristic_i, Optimum),
        names_to = c("Class", "Level", "Metric"),
        names_pattern = "(S\\d|N) (Top|Bottom) (Range|Value)"
    ) |>
    pivot_wider(names_from = c(Level, Metric), values_from = value) |>
    mutate(across(ends_with("Value"), \(x){
        parse_number(x, locale = locale(grouping_mark = "'"))
    }))


class_int <- tribble(
    ~Class_int,~Class,
      1L, "S1",
      2L, "S2",
      3L, "S3",
      4L, "N",
)

crop_characteristics_long <- left_join(
    crop_characteristics_long,
    class_int,
    by = "Class"
    )

crop_characteristics_nested <- crop_characteristics_long |>
    na.omit() |>
    group_by(Characteristic,Characteristic_i, Optimum) |>
    select(Bottom_Value, Top_Value, Class_int) |>
    arrange(Characteristic, Characteristic_i, Bottom_Value) |>
    group_nest(.key = "reclass_table") 

characteristic_variable <- tribble(
    ~Characteristic, ~variable,
    "mean annual temperature", "bio1",
    "mean max. temp of the warmest month", "bio5",
    "mean min. temp of the coldest month", "bio6",
    "annual precipitation", "bio12",
    "min. monthly precipitation", "bio14",
    # leaving the non-temporal data out for now
    # "average annual relative humidity", "ph",
    # "slope", "elevation",
    # "pH","ph",
)


df_to_string <- function(tbl){
    pmap_chr(tbl, \(Bottom_Value, Top_Value, Class_int){
        glue("(A>={Bottom_Value})*(A<{Top_Value})*{Class_int}")
    }) |>
        paste(collapse = " + ")
}

crop_characteristics_nested2 <- crop_characteristics_nested |>
    left_join(characteristic_variable, by = "Characteristic")  |>
    na.omit() |> # removes all non-temporal datasets (for now) |>
    mutate(
        reclass_string = map_chr(reclass_table, \(x) df_to_string(x))
    ) |>
    select(-reclass_table)




################################################################################
## Join filepaths with characteristics #########################################
################################################################################

characteristics_files <- left_join(crop_characteristics_nested2, chelsa_df2, by = "variable", multiple = "all")

write_csv(characteristics_files, "data-csvs/characteristics_files.csv")

# other <- tribble(
#     ~variable, ~file,
#     "ph", "data-raw/phh20/phh2o_5-15cm_mean_10min.tif",
#     "slope", "data-raw/wc2.1_10m_elev.tif"
# ) |>
#     mutate(gcm = "not-applicable",ssp = "not-applicable", period = "not-applicable")



# all_files <- bind_rows(chelsa_df2, other)




