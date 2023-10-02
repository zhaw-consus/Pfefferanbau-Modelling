


library(httpgd)

library(terra)
library(tidyverse)

hgd()


dirs <- list.dirs("data-modelled", recursive = FALSE)
dirs <- dirs[str_detect(dirs, "\\d{4}")]
dirs <- list.dirs(dirs, recursive = FALSE)

# quality check: Do we have maxvals from all gcms, periods and ssps?
list.dirs(dirs, recursive = FALSE) |>
    list.files("maxval.tif", full.names = TRUE) |>
    str_split_fixed("/", 5) |>
    as.data.frame() |>
    mutate(val = 1) |>
    ggplot(aes(V3, val)) +
    geom_col() +
    facet_grid(V2~V4)


# create aggregations of all gcms per period and ssp via the modal
# calculate uncertainty by calulating how often the gcms agreed ()
map(dirs, \(rootpath){
    maxvals <- list.files(rootpath, "maxval\\.tif", recursive = TRUE, full.names = TRUE)

    maxvals_rast <- rast(maxvals)
    maxvals_mode <- modal(maxvals_rast)
    writeRaster(maxvals_mode, file.path(rootpath, "maxval_modal.tif"), overwrite = TRUE)
    maxval_isequal <- maxvals_rast == maxvals_mode
    uncertainty <- sum(maxval_isequal)/nlyr(maxval_isequal)
    writeRaster(uncertainty, file.path(rootpath, "modal_uncertainty.tif"), overwrite = TRUE)
}, .progress = TRUE)



