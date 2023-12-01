outfolder="/cfs/earth/scratch/iunr/shared/iunr-consus/data-modelled"
# rm -r $outfolder
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
  if [ ! -f $outname ]
  then
      echo "File does not exist in Bash"
      gdal_calc.py --overwrite --NoDataValue=0 --type=Byte -A $file --calc="$reclass_string" --outfile $outname
  else
      echo ""
  fi
  
  echo ""
done < data-csvs/characteristics_files.csv


nontemp=$(ls -d $outfolder/non-temporal/* | grep ".tif$")

echo $nontemp


# gets the directiories of the GCMs, excludes diretories with "_" (e.g. _is_limiting)
dirs_gcms=$(ls -d $outfolder/2*/*/*/ | grep -v "/_") # 

# temporary filter for the 2041 GCMs (testing)
dirs_gcms=$(echo "$dirs_gcms" | grep 2041 | grep -v ssp370)

dirs_today=$(ls -d $outfolder/1*)    # gets the directiories of the current climate
dirs=$(echo $dirs_gcms $dirs_today)  # combines the two lists

echo $dirs
for dir in $dirs; do
  echo $dir
  files=$(ls -d $dir/* | grep ".tif$" | grep -v maxval)

  out_subfolder="${dir}/aggregation/"
  mkdir -p $out_subfolder
  
  maxvaltemp="${out_subfolder}/maxval_temp.tif"
  maxval="${out_subfolder}/maxval.tif"

  echo $files
  # seltsamerweise hat nanmax zuerst funktioniert, beim wiederholten mal aber nicht
  # --hideNoData funktioniert nur, weil ich den max Wert suche und 0 als NoData Wert verwendet wird. Für Mittelwertsberechung o.ä. ginge das vermutlich nicht
  if [ ! -f $maxvaltemp ]
  then
      echo "File does not exist"
      gdal_calc.py --hideNoData --quiet --type=Byte --overwrite -A $files --outfile=$maxvaltemp --calc="numpy.nanmax(A,axis=0)"
  else
      echo ""
  fi

  if [ ! -f $maxval ]
  then
      echo "File does not exist"
      gdal_calc.py --hideNoData --quiet --type=Byte --overwrite -A $files $nontemp --outfile=$maxval --calc="numpy.nanmax(A,axis=0)"  
  else
      echo ""
  fi
  

  echo ""
done



