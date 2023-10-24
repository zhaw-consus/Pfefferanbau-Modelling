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

map(dirs_temporal, \(rootdir){
    temporal <- list.files(rootdir, full.names = TRUE)
    temporal <- temporal[!str_detect(temporal, "maxval")]
    all_inputs <- rast(c(temporal, nontemp))
    maxval <- rast(file.path(rootdir, "maxval.tif"))
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




# is_same_summed0 <- sum(is_same, na.rm = TRUE)

# is_same_offset <- is_same *(10^(seq_len(nlyr(is_same))-1))
# is_same_summed1 <- sum(is_same_offset, na.rm = TRUE)

# plot(is_same_summed0)

