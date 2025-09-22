#!/bin/bash
#SBATCH --job-name=sarek-test
#SBATCH --output=logs/sarek-test-%j.out
#SBATCH --account=nn9114k
#SBATCH --time=02:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=16G

module purge
module load Nextflow/24.04.2
#module load Apptainer

mkdir -p logs results_sarek_test

export APPTAINER_CACHEDIR=/cluster/projects/nn9114k/datngu/singularity


nextflow run main.nf -profile saga,test \
  --outdir results_sarek_test \
  -with-report report.html -with-trace trace.txt \
  -with-timeline timeline.html -with-dag dag.png
