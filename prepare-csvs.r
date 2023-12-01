library(terra)
library(tidyverse)
library(httpgd)
# library(tmap)
library(tictoc)
library(glue)
httpgd::hgd()




################################################################################
## Prepare spatial-temporal data (data that varies termporally) ################
################################################################################

data_raw_chelsa <- "/cfs/earth/scratch/iunr/shared/iunr-consus/data-raw/chelsa"

chelsa_files <- list.files(data_raw_chelsa, "\\.tif$",full.names = TRUE)

chelsa_df_all <- tibble(
    filename = basename(chelsa_files),
    path = dirname(chelsa_files),
) |>
    extract(
        filename, 
        c("variable","period",NA,"gcm",NA,"ssp","version"),
        "CHELSA_(\\w+)_(\\d{4}-\\d{4})(_([a-z,0-9,-]+))?(_(\\w+))?_(V\\.\\d\\.\\d).tif",
        remove = FALSE
        )

# We are only interested in the 2041-2070 (ssp126, ssp585) and historic data
interested_future <- chelsa_df_all$period == "2041-2070" & chelsa_df_all$ssp %in% c("ssp126", "ssp585")
interested_historic <- chelsa_df_all$period == "1981-2010"

chelsa_df_all <- chelsa_df_all |>
    filter(interested_future | interested_historic)

chelsa_df_bio <- chelsa_df_all |>
    filter(str_detect(filename, "bio\\d{1,2}"))


# visual quality check: do we have all szenario data?!
chelsa_df_bio |>
    group_by(period, gcm, ssp, variable) |>
    count() |>
    ungroup() |>
    complete(period, nesting(gcm, ssp, variable)) |>
    ggplot(aes(ssp, n, fill = variable)) +
    geom_col() +
    geom_text(aes(label = n), position = position_stack(vjust = 0.5)) +
    facet_grid(period ~ gcm)




chelsa_files_pr <- chelsa_files[str_detect(chelsa_files, "_pr_\\d{2}")]


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
    mutate(
        variable = ifelse(is.na(variable), str_match(filename, "_(pr)_")[,2], variable),
        month = ifelse(is.na(month),str_match(filename, "_(\\d{2})_")[,2], month),
        period = ifelse(is.na(period),str_match(filename, "_(\\d{4}-\\d{4})_")[,2], period)
        ) |>
    mutate(
        period = str_replace(period, "_", "-")
    ) |>
    arrange(gcm, ssp, period, month)



# Visual quality check: do we have all pr-szenario data?!
chelsa_df_pr |>
    group_by(period, gcm, ssp, variable) |>
    count() |>
    ungroup() |>
    complete(period, nesting(gcm, ssp, variable)) |>
    ggplot(aes(ssp, n, fill = variable)) +
    geom_col() +
    geom_text(aes(label = n), position = position_stack(vjust = 0.5)) +
    facet_grid(period ~ gcm)


# We are only interested in the 2041-2070 (ssp126, ssp585) and historic data
interested_future_pr <- chelsa_df_pr$period == "2041-2070" & chelsa_df_pr$ssp %in% c("ssp126", "ssp585")
interested_historic_pr <- chelsa_df_pr$period == "1981-2010"

chelsa_df_pr <- chelsa_df_pr |>
    filter(interested_future_pr | interested_historic_pr) 


chelsa_gcms_ssps_periods <- chelsa_df_pr |>
    distinct(gcm, ssp, period) 



# This file is used in "length-of-dry-season.sh"
write_csv(chelsa_gcms_ssps_periods, "data-csvs/chelsa_gcms_ssps_periods.cvs",col_names = FALSE)


# This file is used in "length-of-dry-season.sh"
write_csv(chelsa_df_pr, "data-csvs/chelsa_pr.csv")



non_temporal <- tribble(
    ~variable, ~file,
    "slope", "data-raw/elevation/wc2.1_30s_elev_slope.tif",
    "humidity", "data-raw/chelsa/CHELSA_hurs_mean_1981-2010_V.2.1.tif",
    "ph", "data-raw/phh20/phh2o_5-15cm_mean_alinged.tif",
) |>
    mutate(temporal = FALSE)


chelsa_df_bio2 <- chelsa_df_bio |>
    group_by(gcm, ssp, period) |>
    transmute(variable, file = file.path(path,filename), temporal = TRUE) |>
    ungroup() |>
    bind_rows(non_temporal)|>
    mutate(across(where(is.character),\(x)replace_na(na_if(x, ""), "not-applicable"))) 


################################################################################
## Prepare Crop Characteristics data  ##########################################
################################################################################


crop_characteristics <- read_csv("data-csvs/Cropdb.Input_Crop_Characteristics.csv")

crop_characteristics <- crop_characteristics |>
# see https://github.zhaw.ch/CONSUS/Pfefferanbau-Modelling/issues/3
    filter(Characteristic != "min. monthly precipitation") 


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
    "length of dry season", "season_sum",
)


scale_offset <- tribble(
    ~variable, ~scale, ~offset,
    "bio12",      0.1,       0, # see #25
    "ph",         0.1,       0, # see https://www.isric.org/explore/soilgrids/faq-soilgrids
    "humidity",  0.01,       0, # gdalinfo
    "bio1",       0.1, -273.15, # see https://chelsa-climate.org/bioclim/
    "bio5",       0.1, -273.15, # see https://chelsa-climate.org/bioclim/
    "bio6",       0.1, -273.15, # see https://chelsa-climate.org/bioclim/
    "slope",        1,       0, # calculated slope myself, in percent
    "season_sum",   1,       0, # calculated this myself, (number of months, values 0-12)
)

# True values would be calculated as: true_value = (pixel_value * scale) + offset
# see https://gdal.org/programs/gdal_edit.html
# pixel_value = (true_value-offset)/scale



crop_characteristics_transformed <- crop_characteristics_long |>
    na.omit() |>
    select(Characteristic, Characteristic_i, Bottom_Value, Top_Value, Class_int, Optimum) |>
    left_join(characteristic_variable, by = "Characteristic")   |>
    left_join(scale_offset, by = "variable")  |> 
    mutate(across(ends_with("_Value"), list("adjusted" = \(x) (x-offset)/scale))) 

crop_characteristics_transformed |>
    mutate(
        Bottom_Value = ifelse(Bottom_Value == -999999.0, -Inf, Bottom_Value),
        Top_Value = ifelse(Top_Value %in% c(99999,999999.0), Inf, Top_Value),
    ) |> 
    ggplot(aes(y = Class_int)) +
    geom_errorbarh(aes(xmin = Bottom_Value, xmax = Top_Value, colour = factor(Class_int)), height = .2, lwd = 2) +
    scale_colour_brewer("Class",palette = "Spectral",direction = -1) +
    facet_wrap(~Characteristic, scale = "free_x", labeller = labeller(Characteristic = str_to_title), ncol = 4) +
    scale_y_continuous("Class") +
    theme_light() +
    theme(legend.position = "none")
    


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
    filter(Characteristic != "length of dry season") |> 
    left_join(chelsa_df_bio2, by = "variable", multiple = "all", relationship = "many-to-many") |>
    mutate(
        outname = paste(str_replace_all(str_remove(Characteristic, "\\."), " ", "-"), Characteristic_i, sep = "-")
    ) 



# This files is used in "model-it.sh" and "get-raster-stats.sh"
characteristics_files |>
    select(-temporal) |>
    # filter(variable == "bio12") |>
    write_csv("data-csvs/characteristics_files.csv")

