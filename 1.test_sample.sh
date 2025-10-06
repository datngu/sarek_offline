#!/bin/bash
#SBATCH --job-name=sarek1
#SBATCH --output=_sarek1-%j.out
#SBATCH --account=nn9114k
#SBATCH --time=100:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=16G

module load Nextflow/24.04.2


mkdir -p logs results_sarek_test_offline

## # Centralized Nextflow Apptainer cache (shared filesystem)
## export APPTAINER_CACHEDIR=/cluster/projects/nn9114k/datngu/apptainer
## export NXF_APPTAINER_CACHEDIR=/cluster/projects/nn9114k/datngu/apptainer


# Run the local clone of nf-core/sarek with own samplesheet and selected tools
# nextflow run main.nf -profile saga \
#   --input /cluster/projects/nn9114k/datngu/projects/variant_calling/toy_data/samplesheet.csv \
#   --genome GATK.GRCh38 \
#   --tools deepvariant,manta,cnvkit \
#   --outdir results_sarek_test2 \

# export APPTAINER_CACHEDIR=/cluster/projects/nn9114k/datngu/projects/variant_calling/offline/sarek_offline/singularity-images
# export NXF_APPTAINER_CACHEDIR=/cluster/projects/nn9114k/datngu/projects/variant_calling/offline/sarek_offline/singularity-images

# export SINGULARITY_CACHEDIR=/cluster/projects/nn9114k/datngu/projects/variant_calling/offline/sarek_offline/singularity-images
# export NXF_SINGULARITY_CACHEDIR=/cluster/projects/nn9114k/datngu/projects/variant_calling/offline/sarek_offline/singularity-images

# export APPTAINER_CACHEDIR=/cluster/projects/nn9114k/datngu/apptainer
# export NXF_APPTAINER_CACHEDIR=/cluster/projects/nn9114k/datngu/apptainer

export SINGULARITY_CACHEDIR=/cluster/projects/nn9114k/datngu/projects/variant_calling/offline/container
export NXF_SINGULARITY_CACHEDIR=/cluster/projects/nn9114k/datngu/projects/variant_calling/offline/container

nextflow run main.nf -profile saga \
  -c offline_hg38.config \
  --input /cluster/projects/nn9114k/datngu/projects/variant_calling/toy_data/samplesheet.csv \
  --genome HG38_OFFLINE \
  --tools manta,cnvkit,haplotypecaller,deepvariant \
  --outdir results_sarek_offline_test \
  -resume
