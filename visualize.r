


library(httpgd)

library(terra)
library(tidyverse)

hgd()

list.files("data-modelled/", "maxval_temp.tif",recursive = TRUE, full.names = TRUE) -> fi

fi[!str_detect(fi, "maxval")] |>
    rast() -> rass