################################################################################
## Determins the limiting factor for each pixel in the modelled data ###########
################################################################################

# What is the limiting factor? This cannot be calulated on the modal values, but
# on original *maxval.tif" files.

library(terra)
library(tidyverse)
nontemp <- list.files("data-modelled/non-temporal", full.names = TRUE)

dirs_temporal <- list.dirs("data-modelled", recursive = FALSE)
dirs_temporal <- dirs_temporal[str_detect(dirs_temporal, "\\d{4}")]
dirs_temporal <- list.dirs(dirs_temporal, recursive = FALSE) |>
    list.dirs(recursive = FALSE)

# get the limiting factor per year, ssp and gcm
map(dirs_temporal, \(rootdir){
    temporal <- list.files(rootdir, full.names = TRUE)
    temporal <- temporal[!str_detect(temporal, "maxval|is_limiting")]
    all_inputs <- rast(c(temporal, nontemp))
    maxval <- rast(file.path(rootdir, "maxval.tif"))

    # if maxval is 1, then no factor is limiting. 
    maxval[maxval == 1] <- NA
    is_limiting <- terra::compare(
        maxval, 
        all_inputs, 
        "==",  
        filename = file.path(rootdir, "is_limiting.tif"), 
        overwrite = TRUE, 
        datatype = "INT1U",
        names = names(all_inputs)
        )
})


# aggregate the limiting factor over all gcm's via the modal value
dirs_temporal |>
    dirname()  |>
    unique() |>
    map(\(rootdir){
    is_limiting_gcm <- list.files(rootdir, "is_limiting.tif", full.names = TRUE, recursive = TRUE) 

    is_limiting_layer_names <- map(is_limiting_gcm, rast) |>
        map(names)


    # do all datasets have the same amout of layers?
    stopifnot(length(unique(lengths(is_limiting_layer_names))) == 1)

    # are the layers in the same order (i.e. same variable with the same names?
    map_lgl(is_limiting_layer_names, \(inner){
        map_lgl(is_limiting_layer_names, \(outer){
            all(inner == outer)
        }) |>
        all()
    }) |>
        all() |>
        stopifnot()


    outdir <- file.path(rootdir, "is_limiting")
    dir.create(outdir,  recursive = TRUE)
    

    # if so, iterate over the first set of layer names
    imap(is_limiting_layer_names[[1]], \(layer_name, layer_number){
        outfile <- file.path(outdir, paste0(layer_name, ".tif"))
        map(is_limiting_gcm, \(x)rast(x, lyrs = layer_number)) |>
            rast() |>
            modal(filename = outfile, wopt = c(datatype = "INT1U"), overwrite = TRUE)
    })
})





