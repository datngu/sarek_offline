#!/bin/bash
#SBATCH --job-name=autism_1
#SBATCH --output=_autism_1-%j.out
#SBATCH --account=p33_norment  
#SBATCH --time=100:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=16G


module purge

module load Python/3.12.3-GCCcore-13.3.0
module load Java/17.0.6
## only do these for the first time
# pip install nextflow

## this for only me, you need to change p33-datn to your username
export PATH="$PATH:/ess/p33/home/p33-datn/.local/bin"


## Plugin, only need if you want to use TSD
export NXF_PLUGINS_DIR=$PWD/plugins
## Offline mode
export NXF_OFFLINE=true
export SINGULARITY_CACHEDIR=$PWD/container
export NXF_SINGULARITY_CACHEDIR=$PWD/container

sed "s|/PATH/TO/|$PWD/|g" offline_hg38_template.config > offline_hg38_fixed.config

TAG=240425_LH00534.A.Project_Djurovic-DNA1-2024-03-01

python3 scripts/generate_sarek_input.py \
  -i "/cluster/projects/p33/users/alexeas/wgs/from_marius/${TAG}/fastq" \
  -o ${TAG}.csv


## Run Sarek


nextflow run nf_sarek/3_5_1 -offline \
  -profile singularity,tsd \
  -c offline_hg38_fixed.config \
  --input ${PWD}/${TAG}.csv \
  --genome HG38_OFFLINE \
  --tools manta,cnvkit,haplotypecaller,deepvariant \
  --outdir out_sarek_${TAG} \
  -resume