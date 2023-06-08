
# Currently, we need to download bio1, 5, 6, 12 and 14 of all GCMs and SSPs
# the dataset data-csvs/chelsa-all-CLIMATOLOGIES.csv holds the urls to 
# all climatologies. This took ages to complie, since I had to manually click on each folder
# TODO: Check if any of the urls are missing and manually add them. 

# this greps all urls with the relevant bioclimatic variables
cat data-csvs/chelsa-all-CLIMATOLOGIES.csv | grep -e bio1_ -e bio5_ -e bio6_ -e bio12_ -e bio14_  


wget -P data-chelsa/ $(cat data-csvs/chelsa-all-CLIMATOLOGIES.csv | grep -e bio1_ -e bio5_ -e bio6_ -e bio12_ -e bio14_)