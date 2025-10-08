#!/bin/bash
#SBATCH --job-name=sarek1
#SBATCH --output=_sarek1-%j.out
#SBATCH --account=nn9114k
#SBATCH --time=100:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=16G

module load Nextflow/24.04.2


export SINGULARITY_CACHEDIR=$PWD/container
export NXF_SINGULARITY_CACHEDIR=PWD/container ## some nf-core versions use this form

## generate the samplesheet with correct paths
sed "s|/PATH/TO/|$PWD/|g" samplesheet_template.csv > samplesheet_fixed.csv

## generate the correct offline config file
sed "s|/PATH/TO/|$PWD/|g" offline_hg38_template.config > offline_hg38_fixed.config

## run the pipeline

nextflow run nf_sarek/3_5_1 -offline \
  -profile singularity,saga \
  -c offline_hg38_fixed.config \
  --input $PWD/samplesheet_fixed.csv \
  --genome HG38_OFFLINE \
  --tools manta,cnvkit,haplotypecaller,deepvariant \
  --outdir results_sarek_offline_test \
  -resume

