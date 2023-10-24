################################################################################
## Calculate difference between future and historic climate scenarios ##########
################################################################################


library(terra)
library(tidyverse)


modal_vals <- list.files("data-modelled", "maxval_modal.tif", recursive = TRUE, full.names = TRUE)

# quality check: did all aggregates work?
# tibble(paths = modal_vals, size = file.info(modal_vals)$size) |>
#     separate(paths, c("junk", "period", "ssp", "junk2"), "/") |>
#     select(-starts_with("junk")) |>
#     ggplot(aes(ssp, size)) +
#     geom_col() + 
#     facet_grid(~period)


## Calculate diifference between historic and future climate szenarios (modal of gcm)
maxval_historic <- rast("data-modelled/1981-2010/maxval.tif")
map(modal_vals, \(x){
    # browser()
    rootdir <- dirname(x)
    maxval_future <- rast(x)
    difference <- maxval_future - maxval_historic
    writeRaster(difference, file.path(rootdir, "maxval_diff.tif"), overwrite = TRUE, datatype = "INT2S")
}, .progress = TRUE)





