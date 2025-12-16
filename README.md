# Sarek 3.5.1: Fully Offline Setup Guide

This guide helps you set up and run the nf-core Sarek 3.5.1 pipeline offline on HPC with these tools: 

- manta
- cnvkit
- haplotypecaller
- deepvariant

**Prerequisites**: Singularity or Apptainer must be available and callable on your system/HPC. Check this yourself or with your system administrator.

## Step 1: Prepare Your Environment

### 1.1 Clone this repository

```bash
git clone https://github.com/datngu/sarek_offline.git
cd sarek_offline

```


### 1.2 Install Nextflow and gsutil 
**You may skip this step if you already have Nextflow and gsutil installed.**

- Create a conda environment for downloading reference files, pipeline, and containers.
- Snakemake is optional, but good to have if you want to run benchmarking with NCBench workflow.

```bash

conda create -n sarek_offline python=3.10 -y
conda activate sarek_offline
## install gsutil for downloading reference files from GATK bundle google cloud storage.
pip install gsutil
## install nextflow, nf-core and snakemake
conda install -c conda-forge -c bioconda nextflow snakemake nf-core -y

```

## Step 2: Download Sarek Pipeline and Containers

### 2.1 Download Sarek Pipeline

- This guide is based on the Singularity container system. You can adjust for other container systems if needed.
- The current latest stable version of Sarek is 3.5.1 (as of September, 2025).


```bash

mkdir -p container
export NXF_SINGULARITY_CACHEDIR=$PWD/container
export NXF_SINGULARITY_CACHE_DIR=$PWD/container  # some nf-core versions use this form


nf-core download sarek \
  --revision 3.5.1 \
  --container-system singularity \
  --compress none \
  --container-cache-utilisation amend \
  --force \
  --outdir $PWD/nf_sarek


```


## 2.2 Fix container symlinks for compatibility


This step may be redundant, but it ensures the container images are correctly set up. When moving files to a different HPC without internet access, soft links may not work as expected (this step fixes that issue).

```bash
## copy to a temp folder
mkdir -p container2
cp -L container/*.img container2
chmod +x container2/*.img

## back to the name container
rm -rf container
mv container2 container

```

# 3. Download Reference Files


To run GATK tools, you need to download the reference files from the GATK bundle Google Cloud Storage.
We will download the reference files for the hg38 assembly. You can adjust for other assemblies if needed.

```bash

# Create output directory
mkdir -p gatk_hg38

# Core reference files
gsutil cp \
  gs://gcp-public-data--broad-references/hg38/v0/Homo_sapiens_assembly38.fasta \
  gs://gcp-public-data--broad-references/hg38/v0/Homo_sapiens_assembly38.fasta.fai \
  gs://gcp-public-data--broad-references/hg38/v0/Homo_sapiens_assembly38.dict \
  gatk_hg38/

# Create BED file excluding ALT contigs
awk 'BEGIN{OFS="\t"}{print $1,0,$2}' \
  gatk_hg38/Homo_sapiens_assembly38.fasta.fai \
  | grep -E '^(chr)?([0-9]+|X|Y|M|MT)\b' \
  > gatk_hg38/noALT.bed

# Known sites VCF files
gsutil cp \
  gs://gcp-public-data--broad-references/hg38/v0/Homo_sapiens_assembly38.dbsnp138.vcf.gz \
  gs://gcp-public-data--broad-references/hg38/v0/Homo_sapiens_assembly38.dbsnp138.vcf.gz.tbi \
  gs://gcp-public-data--broad-references/hg38/v0/Homo_sapiens_assembly38.known_indels.vcf.gz \
  gs://gcp-public-data--broad-references/hg38/v0/Homo_sapiens_assembly38.known_indels.vcf.gz.tbi \
  gs://gcp-public-data--broad-references/hg38/v0/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz \
  gs://gcp-public-data--broad-references/hg38/v0/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz.tbi \
  gatk_hg38/

# Somatic variants
gsutil cp \
  gs://gatk-best-practices/somatic-hg38/af-only-gnomad.hg38.vcf.gz \
  gs://gatk-best-practices/somatic-hg38/af-only-gnomad.hg38.vcf.gz.tbi \
  gatk_hg38/

```


You may check your directory structure now:

```bash
tree gatk_hg38 -L 1

## expected outcome
# gatk_hg38
# ├── af-only-gnomad.hg38.vcf.gz
# ├── af-only-gnomad.hg38.vcf.gz.tbi
# ├── Homo_sapiens_assembly38.dbsnp138.vcf.gz
# ├── Homo_sapiens_assembly38.dbsnp138.vcf.gz.tbi
# ├── Homo_sapiens_assembly38.dict
# ├── Homo_sapiens_assembly38.fasta
# ├── Homo_sapiens_assembly38.fasta.fai
# ├── Homo_sapiens_assembly38.known_indels.vcf.gz
# ├── Homo_sapiens_assembly38.known_indels.vcf.gz.tbi
# ├── Mills_and_1000G_gold_standard.indels.hg38.vcf.gz
# ├── Mills_and_1000G_gold_standard.indels.hg38.vcf.gz.tbi
# └── noALT.bed

```


## 4: Prepare cluster config file


I have prepared `offline_hg38_template.config` as a template to enable customized local reference files, and also adapt to run on Saga of Sigma2 and TSD HPC of UiO.


For our group users, you just need to run this to generate: `offline_hg38_fixed.config`

```bash
sed "s|/PATH/TO/|$PWD/|g" offline_hg38_template.config > offline_hg38_fixed.config
```




For external users, you need to change the `profile` section and `params` section in `offline_hg38_template.config` to fit your environment. Always check the generated config file for correct paths.



## 5 Testing the pipeline with small data:

## 5.1 Download fastq datasets

This is a step to test the installed pipeline with small data before running on your own data. 
The data and benchmarking are based on the NCBench workflow https://github.com/ncbench/ncbench-workflow

More details can be found in the paper: https://doi.org/10.12688/f1000research.140344.1

```bash
mkdir -p test_data

wget https://zenodo.org/records/6513789/files/A006850052_NA12878_200M_R1.fq.gz?download=1 -O test_data/A006850052_NA12878_200M_R1.fq.gz
wget https://zenodo.org/records/6513789/files/A006850052_NA12878_200M_R2.fq.gz?download=1 -O test_data/A006850052_NA12878_200M_R2.fq.gz

wget https://zenodo.org/records/6513789/files/A006850052_NA12878_75M_R1.fq.gz?download=1 -O test_data/A006850052_NA12878_75M_R1.fq.gz
wget https://zenodo.org/records/6513789/files/A006850052_NA12878_75M_R2.fq.gz?download=1 -O test_data/A006850052_NA12878_75M_R2.fq.gz

```

## 5.2 Prepare sample sheet

I prepare a template file name `samplesheet_template.csv`.
The bellow command is to replace the path in the sample sheet template to your current working directory and create `samplesheet_fixed.csv` that you can use to run the pipeline.

```sh
sed "s|/PATH/TO/|$PWD/|g" samplesheet_template.csv > samplesheet_fixed.csv
```


You can now check the structure of your working directory, it should look like this:

```sh
tree -L 1 

# .
# ├── 1.run_test_saga.sh
# ├── CITATIONS.md
# ├── container
# ├── gatk_hg38
# ├── LICENSE
# ├── nf_sarek
# ├── offline_hg38_fixed.config
# ├── offline_hg38_template.config
# ├── plugins
# ├── README.md
# ├── samplesheet_fixed.csv
# ├── samplesheet_template.csv
# └── test_data


```


## 6 Running the pipeline on your HPC

For Saga users, you can submit the job with:

```sh
sbatch 1.run_test_saga.sh
```

For other HPC users, you can run the pipeline with:
```sh

## Optional: load modules if needed
# module load Nextflow/24.04.2

## offline mode
export NXF_OFFLINE=true
export SINGULARITY_CACHEDIR=$PWD/container
export NXF_SINGULARITY_CACHEDIR=$PWD/container  # some nf-core versions use this form

## Generate the samplesheet with correct paths (repeat to be sure)
sed "s|/PATH/TO/|$PWD/|g" samplesheet_template.csv > samplesheet_fixed.csv

## Generate the correct offline config file (repeat to be sure)
sed "s|/PATH/TO/|$PWD/|g" offline_hg38_template.config > offline_hg38_fixed.config

## Run the pipeline
nextflow run nf_sarek/3_5_1 -offline \
  -profile singularity,saga \
  -c offline_hg38_fixed.config \
  --input ${PWD}/samplesheet_fixed.csv \
  --genome HG38_OFFLINE \
  --tools manta,cnvkit,haplotypecaller,deepvariant \
  --outdir results_sarek_offline_test \
  -resume

```    


If the pipeline runs without error, you can check results in the `results_sarek_offline_test` folder.


## Installing Nextflow on TSD (UiO p33)

While there is a Nextflow module on TSD, it does not support plugins and cannot be used for this workflow.

**On TSD p33, you must:**

1. Load the Java module:
  ```bash
  module load Java/17.0.6
  ```
2. Use a local Python (via pip) to install Nextflow:
  ```bash
  module load Python/3.12.3-GCCcore-13.3.0
  pip install nextflow
  ## check installation
  ~/.local/bin/nextflow

  ## Optional: export PATH if needed, replace p33-datn with your username
  export PATH="$PATH:/ess/p33/home/p33-datn/.local/bin"
  ```

**Note:** The system Nextflow module does not support plugins. Always load the Java module before running Nextflow.


## Run test the pipeline on TSD (UiO p33)
You can run the pipeline with:

```sh
sbatch 2.run_test_tsd.sh
```

Please check the `2.run_test_tsd.sh` script for details.


## References

- [nf-core Sarek documentation](https://nf-co.re/sarek)
- [Nextflow documentation](https://www.nextflow.io/docs/latest/index.html)



