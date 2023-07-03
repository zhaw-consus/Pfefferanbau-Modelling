


library(httpgd)

library(terra)
library(tidyverse)


rast(file.path("data-chelsa",chelsa_df_pr$filename[1:12])) -> rass_2011
rast(chelsa_files_pr[str_detect(chelsa_files_pr, "1981")]) -> rass_1981
zurich <- matrix(c(8.53104, 47.37925), ncol = 2)

terra::extract(rass_2011, zurich)
terra::extract(rass_1981, zurich)


rast("data-chelsa-pr/ssp126_gfdl-esm4_2011_2040_01.tif") -> gfdl_esm4_2011

plot(gfdl_esm4_2011)


chelsa_df_pr$period

chelsa_df_pr |>
    filter(str_detect(gcm, "gfdl"), period == "2011_2040", month == "01", ssp == "ssp126") |>
    pull(filename) |>
    (\(x)file.path("data-chelsa",x))() |>
    rast() -> gfdl_esm4_2011_pr

plot(gfdl_esm4_2011_pr<60)