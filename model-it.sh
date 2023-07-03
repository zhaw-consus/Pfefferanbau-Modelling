outfolder="data-modelled"
rm -r $outfolder
# Characteristic,Characteristic_i,Optimum,variable,reclass_string,gcm,ssp,period,file,outname
i=1
while IFS=, read -r Characteristic Characteristic_i Optimum variable reclass_string gcm ssp period file outname
do
  test $i -eq 1 && ((i=i+1)) && continue

  if [ $period = "not-applicable" ]; then
    period="non-temporal"
  fi

  if [ $ssp = "not-applicable" ]; then
    gcm_ssp=""
  else
    gcm_ssp="${ssp}/${gcm}/"
  fi

  out_subfolder="${outfolder}/${period}/${gcm_ssp}"

  mkdir -p $out_subfolder

  outname="${out_subfolder}${outname}.tif"
  gdal_calc.py --NoDataValue=0 --type=Byte -A $file --calc="$reclass_string" --quiet --outfile $outname
  echo ""
done < data-csvs/characteristics_files.csv


nontemp=$(ls -d data-modelled/non-temporal/* | grep ".tif$")

echo $nontemp

# loop over the output of this:
dirs=$(dirname $(find data-modelled -iname "*tif") | sort | uniq | grep -v "non-temporal")

echo $dirs

for dir in $dirs; do
  echo $dir
  files=$(ls -d $dir/* | grep ".tif$")
  echo $files $nontemp
  # seltsamerweise hat nanmax zuerst funktioniert, beim wiederholten mal aber nicht
  # --hideNoData funktioniert nur, weil ich den max Wert suche und 0 als NoData Wert verwendet wird. Für Mittelwertsberechung o.ä. ginge das vermutlich nicht
  gdal_calc.py --hideNoData --quiet --type=Byte --overwrite -A $files $nontemp --outfile=$dir/maxval.tif --calc="numpy.nanmax(A,axis=0)"
  echo ""
done

# dir="data-modelled/2071-2100/ssp585/gfdl-esm4"
# outfile="tmp/maxval.tif"
# gdal_calc.py --hideNoData --quiet --type=Byte --overwrite -A $files $nontemp --outfile=$outfile --calc="numpy.nanmax(A,axis=0)"