
data <- read.csv("data-10min.csv")

for (fi in data$urls){
  filename <-basename(fi)
  print(filename)
  tryCatch(
    download.file(url = fi, destfile = file.path("10min",filename)),
    error = function(e){warning(paste(fi, "failed"))}
    )
}

