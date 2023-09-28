

The script `model.r` prepares all the dataframes, functions etc. to do the modelling.
The script `execute-models.r` executes the modelling of the szerarios for future
and historic data.


on rhel7 (HPC) run this command first:

module load gcc/7.3.0 miniconda3/4.8.2 lsfm-init-miniconda/1.0.0

## Conda


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
rsync -a --progress data-raw/chelsa /cfs/earth/scratch/iunr/shared/iunr-consus

# sync modelled data
rsync -a --progress data-modelled /cfs/earth/scratch/iunr/shared/iunr-consus
```

Since there is no trailing backslash to the source folder, the mentioned folder with be added as a subfolder to the destination folder. 
