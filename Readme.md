
## Project Pipeline.

I'm not too happy about this approach. But I'me developping this step by step and each processing step takes a long time to comptue. I therefore have individual (R- and bash-) Scripts that sometimes depend on each other, which means that reproducing the whole pipeline requires the execution of the scripts in the correct order. 

1. **Obtaining updated data-URLs Chelsa / Climatologies** (optional): Create a textfile containing the URLs of all necessary data on https://envicloud.wsl.ch. The step is considered optional, since a version of these URL already exists under `data-csvs/chelsa-all-CLIMATOLOGIES.csv`. However, in the future, these URLs may not be valid or newer, more accurate data might exist. Be as it may, if step 1 was executed, the resulting textfile needs to be saved as a csv in the aforementioned path.
Datasets needed:
  - `climatologies/(2011-2040|2041-2070|2071-2100)/*/*/(bio|pr|tas)`
  - `climatologies/1981-2010/(pr|tas|bio|hurs|cmi)`
2. **Quality Checks**: Run `one-time-tasks/quality_check_before_download.R` to check if the set of URLs is complete and does not contain unnecessary files.
3. **Download data**: Download the datasets specified in the URL. The scripts `one-time-tasks/download-chelsa.sh` facilitate this (linux only).
4. **Quality Checks**: Run `quality-chekcs.r` to check if the list of downloaded files is complete
5. **Download phh20 and DEM**: Download the dataset *phh20* from soildgrids.org and the digital elevation model from worldclim. The scripts to download these files can be found here: `one-time-tasks/get_phh20.sh` 
6. Run Scripts:
   1. **Prepare CSV**: The script `prepare-csvs.r` prepares all the dataframes ~~, functions etc. to do the modelling.~~ over which the next bash script (gdal) can iterate over. TODO: Add some more quality checks
   2. The script `model-it.sh` executes the modelling of the szerarios for future
and historic data.
   3. The script `length-of-dry-season.sh` calculates the variable "*Lenght of dry season*" from the percipitation dataset.
   4. The script `aggregate_gcms.R` calculate the modal value over all GCMs in a ssp
   5. The script `get_diff_future-historic.r` calculates the difference between the modal value (see prev. step) and the historic value. 
   6. The script `get_limiting_var.r` determins the limiting variable per individual modal. the output is a multilayered tif with 0/1 values (limits / does not limit)


## Conda

asfdsdfasdf
run `conda activate consus` to run the r-code in this repo
run `conda activate geopython` to run the bash files (gdal_* etc) in this repo

(i couldn't create one single environment for some reason. gdal_calc.py is missing from the consus environment, all r stuff is missing from the geopython env)


## Download data locally

go to `/home/nils/ownCloud/Projekte/2023_Pfefferanbau/`

```
scp -r rata@login.hpc.zhaw.ch:/cfs/earth/scratch/rata/consus/data-modelled .
```


### gdal_calc.py

To run gdal_calc.py, you need to find the python file first.

```
find /cfs/earth/scratch/rata/.conda/envs/consus/ -iname "gdal_calc*"

/cfs/earth/scratch/rata/.conda/envs/consus/share/bash-completion/completions/gdal_calc.py
```


### Sync with group folder

To give grea access to the data, I need to manually sync the respective folders with the group folder on the HPC. To do this, run the following commands from the root directory:

``` 
# sync input data
rsync -a --progress /cfs/earth/scratch/rata/consus/data-modelled /cfs/earth/scratch/iunr/shared/iunr-consus

# sync modelled data
rsync -a --progress /cfs/earth/scratch/rata/consus/data-modelled /cfs/earth/scratch/iunr/shared/iunr-consus
```

`-n` or `--dry-run` is to test

Since there is no trailing backslash to the source folder, the mentioned folder with be added as a subfolder to the destination folder. 
