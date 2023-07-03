


library(httpgd)

library(terra)
library(tidyverse)




rast(file.path("data-raw/chelsa",chelsa_df_pr$filename[1:12])) -> rass_2011
rast(file.path("data-raw/chelsa",chelsa_df_pr$filename[chelsa_df_pr$period == "1981-2010"])) -> rass_1981
zurich <- matrix(c(8.53104, 47.37925), ncol = 2)

terra::extract(rass_2011, zurich)
df <- terra::extract(rass_1981, zurich)

df |>
    pivot_longer(everything()) |>
    mutate(name = factor(month.abb[parse_number(name)], levels = month.abb, ordered = TRUE)) |>
    ggplot(aes(name, value)) + geom_col()

plot(rass_1981[[1]])


rast("data-temp/chelsa-pr/ssp126_gfdl-esm4_2011_2040_01.tif") -> gfdl_esm4_2011

plot(gfdl_esm4_2011)


chelsa_df_pr$period

chelsa_df_pr |>
    filter(str_detect(gcm, "gfdl"), period == "2011_2040", month == "01", ssp == "ssp126") |>
    pull(filename) |>
    (\(x)file.path("data-raw/chelsa",x))() |>
    rast() -> gfdl_esm4_2011_pr

plot(gfdl_esm4_2011_pr<60)


rast("data-modelled/2071-2100/ssp585/ukesm1-0-ll/length-of-dry-season-1.tif") -> tmp2

