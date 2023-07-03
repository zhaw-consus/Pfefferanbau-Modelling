

outfolder="data-temp/chelsa-pr"

# i=1
# while IFS=, read -r filename gcm ssp variable month period path
# do
#   test $i -eq 1 && ((i=i+1)) && continue

#   gdal_calc.py -A "data-chelsa/$filename" --type=Byte --outfile="${outfolder}/${ssp}_${gcm}_${period}_${month}.tif" --calc="logical_and(A<600, A>=0)" --NoDataValue=255 
# done < data-csvs/chelsa_pr.csv



# CONTINUE HERE: MAKE THIS RUN FOR AT LEAST THE HISTORICAL DATA, OR BETTER A COMBINED LOOP FOR HISTORICAL AND FUTURE DATA
i=1
while IFS=, read -r filename gcm ssp variable month period path
do
  test $i -eq 1 && ((i=i+1)) && continue

  echo $ssp

  # echo gdal_calc.py -A "data-chelsa/$filename" --type=Byte --outfile="${outfolder}/${ssp}_${gcm}_${period}_${month}.tif" --calc="logical_and(A<600, A>=0)" --NoDataValue=255 
done < data-csvs/chelsa_pr.csv 


groups=$(ls data-temp/chelsa-pr | cut -d '_' -f 1-4 | sort | uniq)


for group in $groups; do
   
    input_file="data-temp/chelsa-pr/${group}"
    temp_file="data-temp/chelsa-pr-sum/${group}.tif"


    ssp=$(echo "$group" | cut -d'_' -f1)
    gcm=$(echo "$group" | cut -d'_' -f2)
    period=$(echo "$group" | cut -d'_' -f 3-4)
    period="${period/_/-}"

    outfile="data-modelled/${period}/${ssp}/${gcm}/length-of-dry-season-1.tif"


    #echo $output_file
    gdal_calc.py --type=Byte --quiet --calc="A+B+C+D+E+F+G+H+I+J+K+L" --outfile=$temp_file --overwrite -A "${input_file}_01.tif" -B "${input_file}_02.tif" -C "${input_file}_03.tif" -D "${input_file}_04.tif" -E "${input_file}_05.tif" -F "${input_file}_06.tif" -G "${input_file}_07.tif" -H "${input_file}_08.tif" -I "${input_file}_09.tif" -J "${input_file}_10.tif" -K "${input_file}_11.tif" -L "${input_file}_12.tif"

    gdal_calc.py --type=Byte --quiet --calc="(A>=0)*(A<2)*1 + (A>=2)*(A<4)*2 + (A>=4)*(A<5)*3 + (A>=5)*(A<=12)*4" --outfile=$outfile --overwrite -A $temp_file
done;




