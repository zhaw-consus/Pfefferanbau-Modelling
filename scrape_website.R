

library(rvest)
library(tidyverse)

page <- read_html("https://worldclim.org/data/cmip6/cmip6_clim30s.html")

myurls <- page %>% 
  html_elements("a") %>% 
  html_attr("href")


data_df <- tibble(urls = myurls) %>% 
  filter(startsWith(urls, "https"),endsWith(urls, "tif"))


data_df <- data_df %>% 
  mutate(filename = basename(urls)) %>% 
  extract(filename,c("variable", "model","szenario", "time"),"_(tmin|tmax|prec|bioc)_(.+)_(ssp126|ssp245|ssp370|ssp585)_(\\d{4}-\\d{4})",remove = FALSE)

write_csv(data_df, "data.csv")
