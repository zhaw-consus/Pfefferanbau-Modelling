
outcsv=data-csvs/chelsa_offset_scale.csv
rm $outcsv
touch $outcsv
i=1
while IFS=, read -r Characteristic Characteristic_i Optimum reclass_string variable gcm ssp period file outname
do
  test $i -eq 1 && ((i=i+1)) && continue
  offset=$(gdalinfo $file | grep Offset)
  stats=$(gdalinfo -stats $file -json | jq ".bands" | jq ".[0]" | jq ".metadata | flatten[]" | jq -r 'to_entries | map("\(.value)") | .[]' | tr '\n' ', ')
  
  mylines="${file}, ${offset}, ${stats}"
  echo $mylines
  echo $mylines >> $outcsv
#   gdalinfo $file | grep Offset
done < data-csvs/characteristics_files.csv