outfolder="data-modelled"
rm -r $outfolder
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
  gdal_calc.py --overwrite --NoDataValue=0 --type=Byte -A $file --calc="$reclass_string" --outfile $outname
  echo ""
done < data-csvs/characteristics_files.csv


nontemp=$(ls -d data-modelled/non-temporal/* | grep ".tif$")

echo $nontemp

# loop over the output of this:
dirs=$(dirname $(find data-modelled -iname "*tif") | sort | uniq | grep -v "non-temporal")

for dir in $dirs; do
  echo $dir
  files=$(ls -d $dir/* | grep ".tif$" | grep -v maxval)
  maxvaltemp="${dir}/maxval_temp.tif"
  maxval="${dir}/maxval.tif"

  echo $files
  # seltsamerweise hat nanmax zuerst funktioniert, beim wiederholten mal aber nicht
  # --hideNoData funktioniert nur, weil ich den max Wert suche und 0 als NoData Wert verwendet wird. Für Mittelwertsberechung o.ä. ginge das vermutlich nicht

  gdal_calc.py --hideNoData --quiet --type=Byte --overwrite -A $files --outfile=$maxvaltemp --calc="numpy.nanmax(A,axis=0)"
  gdal_calc.py --hideNoData --quiet --type=Byte --overwrite -A $files $nontemp --outfile=$maxval --calc="numpy.nanmax(A,axis=0)"  

  echo ""
done

echo "starting rsync"
rsync -a --progress data-modelled /cfs/earth/scratch/iunr/shared/iunr-consus


