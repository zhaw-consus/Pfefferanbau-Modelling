################################################################################
## Determins the limiting factor for each pixel in the modelled data ###########
################################################################################

# What is the limiting factor? This cannot be calulated on the modal values, but
# on original *maxval.tif" files.

library(terra)
library(tidyverse)

data_modelled <- "/cfs/earth/scratch/iunr/shared/iunr-consus/data-modelled"


nontemp <- list.files(file.path(data_modelled,"non-temporal"), full.names = TRUE)

dirs_temporal <- list.dirs(data_modelled, recursive = FALSE)
dirs_temporal1 <- dirs_temporal[str_detect(dirs_temporal, "2\\d{3}-\\d{4}")]
subdirs_temporal1 <- list.dirs(dirs_temporal1, recursive = FALSE) |>
    list.dirs(recursive = FALSE)

subdirs_temporal1 <- subdirs_temporal1[!str_detect(basename(subdirs_temporal1), "^_")]

# filter only ssps and periods of interest
subdirs_temporal1 <- subdirs_temporal1[str_detect(subdirs_temporal1, "2041-2070|2071-2100") & str_detect(subdirs_temporal1, "ssp126|ssp585")]

subdirs_temporal2 <- dirs_temporal[str_detect(dirs_temporal, "1\\d{3}-\\d{4}")]

subdirs_temporal <- c(subdirs_temporal1, subdirs_temporal2)


# which gcms / ssps are missing files and which ones?
tibble(dir = subdirs_temporal1) |>
    mutate(n_files = map_int(dir, \(x)length(list.files(x))))  |>
    # filter(n_files < 10) |>
    mutate(
        ssp = str_extract(dir, "ssp\\d{3}"),
        gcm = basename(dir),
        period = str_extract(dir, "\\d{4}-\\d{4}")
        )  |>
    ggplot(aes(ssp, n_files, fill = n_files == 10)) +
    geom_col() +
    facet_grid(period~gcm) +
    theme(legend.position = "none")

# get the limiting factor per year, ssp and gcm
map(subdirs_temporal, \(rootdir){
    browser()
    temporal <- list.files(rootdir, "\\.tif$", full.names = TRUE)
    aggregation_subfolder <- file.path(rootdir, "aggregation")

    all_inputs <- rast(c(temporal, nontemp))
    maxval <- rast(file.path(aggregation_subfolder, "maxval.tif"))

    aggregation_subfolder_limiting <- file.path(aggregation_subfolder, "is_limiting")
    dir.create(aggregation_subfolder_limiting, recursive = TRUE)

    filenames <- file.path(aggregation_subfolder_limiting, paste0(names(all_inputs), ".tif"))
    
    # if maxval is 1, then no factor is limiting. 
    is_limiting <- terra::compare(
        maxval, 
        all_inputs, 
        "=="
        )
    is_limiting[maxval == 1] <- NA

    writeRaster(is_limiting, filename = filenames, overwrite = TRUE, datatype = "INT1U")
})




    


# aggregate the limiting factor over all gcm's via the modal value
# careful! this loop must be adjusted for the fact that the above loop was re-
# configured in such a way that each layer is it's own file.
# subdirs_temporal1 |>
#     dirname()  |>
#     unique() |>
#     map(\(rootdir){
#         browser()

#         aggregation_subfolder <- file.path(rootdir, "aggregation")

#         is_limiting_gcm <- list.files(rootdir, "is_limiting.tif", full.names = TRUE, recursive = TRUE) 

#         root_subdirs <- list.dirs(rootdir, recursive = FALSE)
#         root_subdirs <- root_subdirs[basename(root_subdirs) != "_is_limiting"]
#         root_subdirs_is_limiting <- list.dirs(root_subdirs)
#         root_subdirs_is_limiting <- root_subdirs_is_limiting[endsWith(root_subdirs_is_limiting, "aggregation/is_limiting")]
      
        
#         outdir <- file.path(rootdir, "_is_limiting")
#         dir.create(outdir,  recursive = TRUE)
        

#         # if so, iterate over the first set of layer names
#         imap(is_limiting_layer_names[[1]], \(layer_name, layer_number){
#             outfile <- file.path(outdir, paste0(layer_name, ".tif"))
#             map(is_limiting_gcm, \(x)rast(x, lyrs = layer_number)) |>
#                 rast() |>
#                 modal(filename = outfile, wopt = c(datatype = "INT1U"), overwrite = TRUE)
#         })
# })





