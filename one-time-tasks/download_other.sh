
# get phh20 values from soilgrids.org
IGH="+proj=igh +lat_0=0 +lon_0=0 +datum=WGS84 +units=m +no_defs" # proj string for Homolosine projection
SG_URL="/vsicurl?max_retry=3&retry_delay=1&list_dir=no&url=https://files.isric.org/soilgrids/latest/data"

gdal_translate \
    -co "TILED=YES" -co "COMPRESS=DEFLATE" -co "PREDICTOR=2" -co "BIGTIFF=YES" \
    $SG_URL"/phh2o/phh2o_5-15cm_mean.vrt" \
    "data-raw/phh20/phh2o_5-15cm_mean.tif"


# get elevation data in 30x resolution
wget --no-check-certificate -P data-raw/elevation https://biogeo.ucdavis.edu/data/worldclim/v2.1/base/wc2.1_30s_elev.zip
unzip -d data-raw/elevation data-raw/elevation/wc2.1_30s_elev.zip