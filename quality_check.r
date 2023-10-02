################################################################################
## Quality Checks for downloaded data ##########################################
################################################################################



## CHELSA ######################################################################

chelsa <- tibble(path = list.files("data-raw/chelsa", full.names = TRUE))

chelsa$variable <- str_match(chelsa$path, "(bio(14|12|5|6|1)_|hurs|cmi|pr)")[, 2]

sum(is.na(chelsa$variable))
unique(chelsa$variable )

period <- str_match(chelsa$path, "\\d{4}([-_]\\d{4})?")[,1]
unique(period)
chelsa$period <- str_replace(period, "_", "-")
sum(is.na(chelsa$period))


chelsa$ext <- str_split(chelsa$path, "\\.") |>
    sapply(\(x)x[length(x)])

unique(chelsa$ext)

chelsa <- chelsa |>
    filter(ext != "xml")

chelsa_historic <- chelsa |>
    filter(period == "1981-2010") 


chelsa_future <- chelsa |>
    filter(period != "1981-2010") 


## CHELSA FUTURE ###############################################################

chelsa_future$ssp <- str_match(chelsa_future$path, "ssp\\d{3}")[, 1]
unique(chelsa_future$ssp)

chelsa_future$gcm <- str_match(chelsa_future$path, "((gfdl|ipsl|mpi|mri|ukesm1)-[a-z0-9\\-]+)_")[,2]
unique(chelsa_future$gcm)


# A visual Check: for each gcm (column), period (row) and ssp (bar) we should have
# 12 "pr" datasets and 5 "bio" datasets (bio 1, 5, 6, 12, 14)
# The data pr data from ukesm1, 2011-2040 ssp126 is missing and cannot be found on the server
chelsa_future |>
    group_by(period, gcm, ssp, variable) |>
    count(sort = TRUE) |>
    ungroup() |>
    # complete(period, nesting(gcm, ssp, variable)) |>
    ggplot(aes(ssp, n, fill = variable)) +
    geom_col() +
    geom_text(aes(label = n), position = position_stack(vjust = 0.5)) +
    facet_grid(period ~ gcm)





## CHELSA HISTORIC #############################################################

chelsa_historic |>
    filter(variable == "pr") 

# Since the historic data is less complex, it's enough to just check the table
# We need the same amout of data as for the future data, but in addition we need
# cmi and hurs
chelsa_historic |>
    group_by(variable) |>
    count(sort = TRUE) 
