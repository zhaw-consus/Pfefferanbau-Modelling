
groups=$(ls data-chelsa-pr | cut -d '_' -f 1-4 | sort | uniq)


for group in $groups; do

#   months=()
#   for ((i=1; i<=12; i++)); do
#     months+=("${outfolder}/${group}_$(printf "%02d" "$i").tif")
#   done
  
#   delimiter=" "  # Set the delimiter to a comma
#   concatenated_string=$(printf "%s${delimiter}" "${months[@]}")
#   gdal_calc.py --type=Byte -A $concatenated_string --calc="numpy.sum(A, axis = 1)" --outfile=data-chelsa-pr-sum/test.tif
    group2="data-chelsa-pr/${group}"

    gdal_calc.py --type=Byte --calc="A+B+C+D+E+F+G+H+I+J+K+L" --outfile=data-chelsa-pr-sum/test.tif --overwrite -A "${group2}_01.tif" -B "${group2}_02.tif" -C "${group2}_03.tif" -D "${group2}_04.tif" -E "${group2}_05.tif" -F "${group2}_06.tif" -G "${group2}_07.tif" -H "${group2}_08.tif" -I "${group2}_09.tif" -J "${group2}_10.tif" -K "${group2}_11.tif" -L "${group2}_12.tif"
done;