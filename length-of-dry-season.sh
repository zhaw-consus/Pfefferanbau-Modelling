

tempfolder1="data-temp/chelsa-pr"
tempfolder2="data-temp/chelsa-pr-sum"
data_modelled_dir="/cfs/earth/scratch/iunr/shared/iunr-consus/data-modelled"

# Step 1: For each monthly percipitation sum, classify the raster into boolen:
# value > 600 -> True
# value < 600 -> False
# (Nodata: 255)
i=1
while IFS=, read -r filename gcm ssp variable month period path
do
  test $i -eq 1 && ((i=i+1)) && continue


  
  
  
  if [ "$ssp" == "NA" ]; then
    outfile="${tempfolder1}/${period}_${month}.tif"
  else
    outfile="${tempfolder1}/${ssp}_${gcm}_${period}_${month}.tif"
  fi

  if test -f "$outfile"; then
    echo "${outfile} exists. Nothing happens"

  else
    echo "${outfile} does not exist"
    gdal_calc.py --overwrite -A "data-raw/chelsa/$filename" --type=Byte --outfile=$outfile --calc="logical_and(A<600, A>=0)" --NoDataValue=255
  fi
  
done < data-csvs/chelsa_pr.csv 



# Step 2: For each year
# 1. sum the monthly boolean rasters
# 2. classify the sum into 4 classes, depending on the number of months with 
# percipitation < 600
while IFS=, read -r gcm ssp period
do
  if [ "$ssp" == "NA" ]; then
    infile="${tempfolder1}/${period}"
    tempfile="${tempfolder2}/${period}.tif"
    outfile="${data_modelled_dir}/${period}/length-of-dry-season-1.tif"
  else
    infile="${tempfolder1}/${ssp}_${gcm}_${period}"
    tempfile="${tempfolder2}/${ssp}_${gcm}_${period}.tif"
    outfile="${data_modelled_dir}/${period}/${ssp}/${gcm}/length-of-dry-season-1.tif"
  fi
    

  if test -f "$tempfile"; then
    echo "${tempfile} exists. Nothing is done"
  else
    echo "${tempfile} does not exist"
    gdal_calc.py --type=Byte --quiet --calc="A+B+C+D+E+F+G+H+I+J+K+L" --outfile=$tempfile --overwrite -A "${infile}_01.tif" -B "${infile}_02.tif" -C "${infile}_03.tif" -D "${infile}_04.tif" -E "${infile}_05.tif" -F "${infile}_06.tif" -G "${infile}_07.tif" -H "${infile}_08.tif" -I "${infile}_09.tif" -J "${infile}_10.tif" -K "${infile}_11.tif" -L "${infile}_12.tif"
  fi

  

  
  if test -f "$outfile"; then
    echo "${outfile} exists. Nothing happens"
  else
    echo "${outfile} does not exist"    
    gdal_calc.py --type=Byte --quiet --calc="(A>=0)*(A<2)*1 + (A>=2)*(A<4)*2 + (A>=4)*(A<5)*3 + (A>=5)*(A<=12)*4" --outfile=$outfile --overwrite -A $tempfile
  fi
  
done < data-csvs/chelsa_gcms_ssps_periods.cvs





