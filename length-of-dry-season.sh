

outfolder="data-chelsa-pr"

i=1
while IFS=, read -r filename gcm ssp variable month period path
do
  test $i -eq 1 && ((i=i+1)) && continue

  gdal_calc.py -A "data-chelsa/$filename" --type=Byte --outfile="${outfolder}/${ssp}_${gcm}_${period}_${month}.tif" --calc="logical_and(A<600, A>=0)" --NoDataValue=255 
done < data-csvs/chelsa_pr.csv




