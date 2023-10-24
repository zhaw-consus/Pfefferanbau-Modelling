################################################################################
## Prepare the data-csvs/chelsa-all-CLIMATOLOGIES.csv dataset (for downloading)
################################################################################


## Attention: This quality check is not complete, but more of a sanity check.
## To make it complete, I would have to check 
## 1. if all the files we NEED are in the list
## 2. if NONE of the files we DONT NEED are in the list 
## There are some safety measures for the 2. case in the script download-chelsa.sh
## and there are more quality checks later on. So I think this is enough for now.

all_climatologies <- read_csv("data-csvs/chelsa-all-CLIMATOLOGIES.csv")

all_climatologies$period <- str_match(all_climatologies$URL, "\\d{4}-\\d{4}")[, 1]
all_climatologies$ssp <- str_match(all_climatologies$URL, "ssp\\d{3}")[, 1]
all_climatologies$gcm <- str_match(all_climatologies$URL, "((GFDL|IPSL|MPI|MRI|UKESM1)-[\\w-]+)")[, 2]
all_climatologies$variable <- str_match(all_climatologies$URL, "(bio(14|12|5|6|1)_|hurs|cmi|pr)")[, 2]


# quality check: do we have all urls?
# 2011-2040 UKESM1-0-LL ssp126 is missing and cannot be found on the server
# (https://envicloud.wsl.ch)
all_climatologies |>
    filter(period != "1981-2010") |>
    filter(!is.na(variable)) |>
    # mutate(variable = ifelse(str_detect(variable, "bio"), "bio", variable)) |>
    group_by(period, gcm, ssp, variable) |>
    count() |>
    ungroup() |>
    complete(period, nesting(gcm, ssp, variable)) |>
    ggplot(aes(ssp, n, fill = variable)) +
    geom_col() +
    geom_text(aes(label = n), position = position_stack(vjust = 0.5)) +
    facet_grid(period ~ gcm)


all_climatologies |>
    filter(period == "1981-2010") 