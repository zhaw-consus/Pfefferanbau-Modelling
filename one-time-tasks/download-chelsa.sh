
# Currently, we need to download bio1, 5, 6, 12 and 14 of all GCMs and SSPs
# the dataset data-csvs/chelsa-all-CLIMATOLOGIES.csv holds the urls to 
# all climatologies. This took ages to complie, since I had to manually click on each folder

# Over time, I had to extend the origin list of urls with the ones I missed originally.
# Thefore, the List of URLs now has a header (URL) and is deduplicated. To simplify
# things, i keep using the same csv to download the data, and just add the option
# "-nc" (no cloobber) to prevent redownloading the same file. If, for some reason
# I want to redownload all the files; i should first remove the old files.

# this greps all urls with the relevant bioclimatic variables

dest_dir="/cfs/earth/scratch/iunr/shared/iunr-consus/data-raw/chelsa"


# how many files will be downloaded?
bioclim=$(cat data-csvs/chelsa-all-CLIMATOLOGIES.csv | grep -e bio1_ -e bio5_ -e bio6_ -e bio12_ -e bio14_)
echo $bioclim | wc -w
wget -P $dest_dir -nc $bioclim


# humidity
humidity=$(cat data-csvs/chelsa-all-CLIMATOLOGIES.csv | grep -e hurs)
echo $humidity | wc -w
wget -P $dest_dir -nc $humidity


# climate moisture index (see #10)
cmi=$(cat data-csvs/chelsa-all-CLIMATOLOGIES.csv | grep -e cmi)
echo $cmi | wc -w
wget -P $dest_dir -nc $cmi

# precipitation
# Excluding the files "monthly". These are the monthly precipitation values *per year*
# Since we are only using the monthly values per *period* for the future data, I think
# it's enough to do the same for the historical data.
# Also excluding the only netcdf file, which is at a 5km resolution and shouldn't even
# be in the list of files.
pr_files=$(cat data-csvs/chelsa-all-CLIMATOLOGIES.csv | grep -e pr | grep GLOBAL/climatologies | grep .tif$)
echo $pr_files | wc -w
wget -P $dest_dir -nc $pr_files

# I needed to remove the monthly files, since I exceeded my quota and they took
# about 400GB of disk space (from the 2TB available)
# rm $(find $dest_dir | grep CHELSA_pr_[0-9][0-9]_[0-9][0-9][0-9][0-9]_V) # remove the monthly files
