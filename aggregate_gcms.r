################################################################################
## Aggregates the GCMS to a single model via the modal value ###################
################################################################################

library(terra)
library(tidyverse)

data_modelled <- "/cfs/earth/scratch/iunr/shared/iunr-consus/data-modelled"

dirs <- list.dirs(data_modelled, recursive = FALSE)
dirs <- dirs[str_detect(dirs, "2\\d{3}-2\\d{3}")] # removes non-temporal and current
dirs <- list.dirs(dirs, recursive = FALSE)

# temporary filter for testing
dirs <- dirs[str_detect(dirs,"2041-2070|2071-2100") & !str_detect(dirs, "ssp370")]

# quality check: Do we have maxvals from all gcms, periods and ssps?
list.dirs(dirs, recursive = FALSE) |>
    list.files("maxval.tif", recursive = TRUE, full.names = TRUE) |>
    tibble(paths = _) |>
    mutate(
        ssp = str_extract(paths, "ssp\\d{3}"),
        gcm = map_chr(str_split(paths, "/"), \(x)x[11]),
        period = str_extract(paths, "\\d{4}-\\d{4}")
        )  |>
    mutate(size = file.info(paths)$size/1e6) |>
    ggplot(aes(ssp, size)) +
    geom_col() +
    facet_grid(period~gcm)


# create aggregations of all gcms per period and ssp via the modal
# calculate uncertainty by calulating how often the gcms agreed ()
map(dirs, \(rootpath){
    maxvals <- list.files(rootpath, "maxval\\.tif$", recursive = TRUE, full.names = TRUE)

    maxvals_rast <- rast(maxvals)

    maxval_modal <- file.path(rootpath, "maxval_modal.tif")

    if(!file.exists(maxval_modal)){
        maxvals_mode <- modal(
            maxvals_rast, 
            filename = maxval_modal, 
            overwrite = TRUE, 
            wopt = list(datatype = "INT1U")
        )

        maxval_isequal <- maxvals_rast == maxvals_mode
        uncertainty <- sum(maxval_isequal, na.rm = TRUE)/nlyr(maxval_isequal)
        writeRaster(uncertainty, file.path(rootpath, "modal_uncertainty.tif"), overwrite = TRUE)
    }
    

}, .progress = TRUE)
