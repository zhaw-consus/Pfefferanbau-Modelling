
source("model.r")

# calculate suitability for:
# - 1 characteristic
# - 1 GCM
# - 1 SSP
# - 1 period
tic()
min_monthly_perc <- data_10min_nested |>
    filter(GCM == "ACCESS-CM2", SSP == "ssp585", period == "2081-2100") |>
    pull(characteristic_df) |>
    pluck(1) |>
    suitability("min. monthly precipitation")
toc()

plot(min_monthly_perc)

# calculate suitability for:
# - ALL characteristic
# - 1 GCM
# - 1 SSP
# - 1 period
tic()
GCM_sel <- "ACCESS-CM2"
SSP_sel <- "ssp585"
period_sel <- "2061-2080"
data_10min_nested |>
    filter(GCM == GCM_sel, SSP == SSP_sel, period == period_sel) |>
    pull(characteristic_df) |>
    pluck(1) |>
    suitability_all(method = "both")
toc()


# calculate suitability for:
# - ALL characteristic
# - ALL GCM
# - 1 SSP
# - 1 period
# takes approx 1 minute
tic()
SSP_sel <- "ssp585"
period_sel <- "2061-2080"
data_10min_nested |>
    filter(SSP == SSP_sel, period == period_sel)|>
    pull(characteristic_df) |>
    map(\(x) suitability_all(x), .progress = TRUE)
toc()





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


suit_ph <- suitability(crop_characteristics_nested2, "pH")
suit_slope <- suitability(crop_characteristics_nested2, "slope")




