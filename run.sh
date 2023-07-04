#!/usr/bin/env bash

#SBATCH --job-name=consus         ## name, der in squeue ersichtlich ist
#SBATCH --partition=earth-1   
# #SBATCH --array=0-25   
   
#SBATCH --nodes=1                    ## wie viele nodes braucht der task
#SBATCH --cpus-per-task=1   
#SBATCH --ntasks-per-node=1          ## wie viele tasks auf dem node ausgeführt werden sollen (in diesem fall = wie viele CPUs benötigt werden)
#SBATCH --time=10:00:00		         ## wie lange braucht er MAXIMAL (danach wird er gekillt)?
#SBATCH --mail-type=END,FAIL         ## schickt ein mail falls job fertig oder failed
#SBATCH --mail-user=rata@zhaw.ch     ## an wen soll das mail geschickt werden?
#SBATCH --output=outputlog.%A_%a.log

# ## load conda module
module load gcc/7.3.0 miniconda3/4.8.2 lsfm-init-miniconda/1.0.0

# ## activate your already installed environment
# ##  install via
# ##
# ##   conda env create -f environment.yml
# ##
# ##  e.g.
# ##   - on head node
# ##   - or in seperate job
# ##   - or before trying to activate
# ##    (but only ONCE,
# ##      otherwise the job will fail because the enviornment already exists)
# ##
conda activate geopython

bash model-it.sh
