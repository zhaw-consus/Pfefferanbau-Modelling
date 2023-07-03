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


chelsa_files <- list.files("data-raw/chelsa", "\\.tif$|\\.nc$",full.names = TRUE)
precipitation_bool <- str_detect(chelsa_files, "pr")

chelsa_files_pr <- chelsa_files[precipitation_bool]
chelsa_files_bio <- chelsa_files[!precipitation_bool]


chelsa_df <- tibble(
    filename = basename(chelsa_files_bio),
    path = dirname(chelsa_files_bio),
) |>
    extract(
        filename, 
        c("variable","period",NA,"gcm",NA,"ssp","version"),
        "CHELSA_(\\w+)_(\\d{4}-\\d{4})(_([a-z,0-9,-]+))?(_(\\w+))?_(V\\.\\d\\.\\d).tif",
        remove = FALSE
        )

chelsa_df_pr <- tibble(
    filename = basename(chelsa_files_pr),
    path = dirname(chelsa_files_pr),
) |>
    extract(
        filename, 
        c("gcm", "ssp", "variable","month","period"),
        "CHELSA_([a-z,0-9,-]+)_r1i1p1f1_w5e5_(ssp\\d{3})_(pr)_(\\d{2})_(\\d{4}_\\d{4})_norm.tif",
        remove = FALSE
        ) |>
    arrange(gcm, ssp, period, month)

write_csv(chelsa_df_pr, "data-csvs/chelsa_pr.csv")



chelsa_df <- chelsa_df |>
    filter(startsWith(variable,"bio"))


non_temporal <- tribble(
    ~variable, ~file,
    "slope", "data-raw/elevation/wc2.1_30s_elev_slope.tif",
    "humidity", "data-chelsa/CHELSA_hurs_mean_1981-2010_V.2.1.tif",
    "ph", "data-raw/phh20/phh2o_5-15cm_mean_alinged.tif",
) |>
    mutate(temporal = FALSE)


chelsa_df2 <- chelsa_df |>
    group_by(gcm, ssp, period) |>
    transmute(variable, file = file.path(path,filename), temporal = TRUE) |>
    ungroup() |>
    bind_rows(non_temporal)|>
    mutate(across(where(is.character),\(x)replace_na(na_if(x, ""), "not-applicable"))) 
# todo: length-of-dry-season



################################################################################
## Prepare Crop Characteristics data  ##########################################
################################################################################


crop_characteristics <- read_csv("data-csvs/Cropdb.Input_Crop_Characteristics.csv")


crop_characteristics |>
    filter(Characteristic == "length of dry season")

crop_characteristics <- crop_characteristics |>
# see https://github.zhaw.ch/CONSUS/Pfefferanbau-Modelling/issues/3
    filter(Characteristic != "min. monthly precipitation") |>
    filter(Characteristic != "length of dry season") # todo: include this


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


characteristic_variable <- tribble(
    ~Characteristic, ~variable,
    "mean annual temperature", "bio1",
    "mean max. temp of the warmest month", "bio5",
    "mean min. temp of the coldest month", "bio6",
    "annual precipitation", "bio12",
    "min. monthly precipitation", "bio14",
    "average annual relative humidity", "humidity",
    "slope", "slope",
    "pH","ph",
)


scale_offset <- tribble(
    ~variable, ~scale, ~offset,
    "bio12",        1,       0, # these values are as expected
    "ph",         0.1,       0, # see https://www.isric.org/explore/soilgrids/faq-soilgrids
    "humidity",  0.01,       0, # gdalinfo
    "bio1",       0.1, -273.15, # see https://chelsa-climate.org/bioclim/
    "bio5",       0.1, -273.15, # see https://chelsa-climate.org/bioclim/
    "bio6",       0.1, -273.15, # see https://chelsa-climate.org/bioclim/
    "slope",        1,       0, # calculated slope myself, in percent
)

# True values would be calculated as: true_value = (pixel_value * scale) + offset
# see https://gdal.org/programs/gdal_edit.html
# pixel_value = (true_value-offset)/scale

crop_characteristics_long

crop_characteristics_transformed <- crop_characteristics_long |>
    na.omit() |>
    select(Characteristic, Characteristic_i, Bottom_Value, Top_Value, Class_int, Optimum) |>
    left_join(characteristic_variable, by = "Characteristic")   |>
    left_join(scale_offset, by = "variable")  |>
    mutate(across(ends_with("_Value"), list("adjusted" = \(x) (x-offset)/scale))) 
    

crop_characteristics_transformed |>
    mutate(
        Bottom_Value = ifelse(Bottom_Value == -999999.0, -Inf, Bottom_Value),
        Top_Value = ifelse(Top_Value == 999999.0, Inf, Top_Value),
    ) |>
    ggplot(aes(Bottom_Value, Class_int)) +
    geom_step() +
    scale_y_continuous(limits = c(0,4))+
    facet_wrap(~Characteristic, scale = "free_x") 
    


crop_characteristics_nested <- crop_characteristics_transformed |>
    select(-scale, -offset, -matches("_Value$")) |>
    rename_with(\(x)str_remove(x, "_adjusted"), ends_with("_adjusted")) |>
    group_by(Characteristic,Characteristic_i, Optimum, variable) |>
    arrange(Characteristic, Characteristic_i, Bottom_Value)  |>
    group_nest(.key = "reclass_table") 







df_to_string <- function(tbl){
    pmap_chr(tbl, \(Bottom_Value, Top_Value, Class_int){
        glue("(A>={Bottom_Value})*(A<{Top_Value})*{Class_int}")
    }) |>
        paste(collapse = " + ")
}


crop_characteristics_nested2 <- crop_characteristics_nested |>
    mutate(
        reclass_string = map_chr(reclass_table, \(x) df_to_string(x))
    ) |>
    select(-reclass_table) 




################################################################################
## Join filepaths with characteristics #########################################
################################################################################

characteristics_files <- crop_characteristics_nested2  |>
    left_join(chelsa_df2, by = "variable", multiple = "all") |>
    mutate(
        outname = paste(str_replace_all(str_remove(Characteristic, "\\."), " ", "-"), Characteristic_i, sep = "-")
    ) 


characteristics_files|>
    select(-temporal) |>
    filter(period %in% c("1981-2010", "2071-2100", "not-applicable")) |>
    filter(ssp %in% c("not-applicable","ssp585")) |>
    filter(gcm %in% c("not-applicable","mpi-esm1-2-hr")) |>
    write_csv("data-csvs/characteristics_files_filter.csv")

# characteristics_files|>
#     select(-temporal) |>
#     filter(period == "1981-2010") |>
#     write_csv("data-csvs/characteristics_files_filter.csv")


characteristics_files |>
    select(-temporal) |>
    write_csv("data-csvs/characteristics_files.csv")







