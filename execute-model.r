
source("model.r")


SSP_sel <- "ssp585"
period_sel <- "2061-2080"
ssp585_2061_2080 <- map(characteristics, \(x){
    char_clean <- clean_name(x)

    filename_base <- file.path("data-modelled",paste(char_clean, period_sel,SSP_sel, sep ="_"))
    raster_stack <- suitability_across(data_10min_nested, x, SSP_sel, period_sel, TRUE)

    filenames <- paste0(filename_base, c(".tif","_modal_freq.tif"))
    # print(filenames)
    writeRaster(raster_stack, filename = filenames,datatype = "INT1U",overwrite = TRUE)

    raster_out <- raster_stack[[1]]
    names(raster_out) <- x

    raster_out
})


characteristic_df <- data_10min_nested$characteristic_df[[1]]
characteristic <- "annual precipitation"



ph_slope <- map(c("pH","slope"), \(x){
    filename_base <- file.path("data-modelled",paste(x,"tif", sep ="."))
    raster_out <- suitability(crop_characteristics_nested2, x)
}) 
ph_slope[[1]] <- resample(ph_slope[[1]], ph_slope[[2]])

ph_slope <- rast(ph_slope)

writeRaster(ph_slope, filename = file.path("data-modelled",paste(names(ph_slope), "tif",sep = ".")), datatype = "INT1U", overwrite = TRUE)

ssp585_2061_2080_max <- c(ssp585_2061_2080, ph_slope) |>
    rast() |>
    max()

writeRaster(ssp585_2061_2080_max, filename = file.path("data-modelled",glue("{period_sel}_{SSP_sel}_MAX.tif")),datatype = "INT1U")


suitability_historic <- suitability_all(characteristic_df_historic)


suitability_historic_max <- max(c(suitability_historic, ph_slope))
names(suitability_historic_max) <- "1970-2000_MAX"

writeRaster(
    suitability_historic_max, 
    filename = file.path("data-modelled",paste0(names(suitability_historic_max), ".tif")),
    datatype = "INT1U", 
    overwrite = TRUE
    )

filenames <- file.path("data-modelled",paste0(clean_name(names(suitability_historic)),"_1970-2000", ".tif"))
writeRaster(suitability_historic, filename = filenames, datatype = "INT1U", overwrite = TRUE)

