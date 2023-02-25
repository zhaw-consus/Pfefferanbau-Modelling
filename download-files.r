
data <- read.csv("data-10min.csv")

for (fi in data$urls[1:2]){
  filename <-basename(fi)
  print(filename)
  tryCatch(
    download.file(url = paste(fi,"k"), destfile = file.path("10min",filename)),
    error = function(e){warning(paste(fi, "failed"))}
    )
}

