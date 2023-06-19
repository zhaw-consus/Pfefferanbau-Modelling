

The script `model.r` prepares all the dataframes, functions etc. to do the modelling.
The script `execute-models.r` executes the modelling of the szerarios for future
and historic data.

## Conda

run `conda activate consus` to run the code in this repo

Strangely, this does not seem to work anymore. Something seems to be messed up with the paths. 

```
/cfs/earth/scratch/rata/.conda/envs/consus
```

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



