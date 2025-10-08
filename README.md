# Sarek 3.5.1: Fully Offline Setup Guide

This guide helps you set up and run the nf-core Sarek 3.5.1 pipeline offline on HPC with these tools: 

- manta
- cnvkit
- haplotypecaller
- deepvariant

## Step 1: Prepare Your Environment

**Preprequisites**: singularity or apptainer must avaiable and callable on your systen/HPC, you must check this yourself or with your system administrator.

**You may skip this step if you already have Nextflow and gsutil installed.**

- Create a conda environment for downloading reference files, pipeline and containers.

- You can skip this step if you already have Nextflow and gsutil installed.

- Snakemake is optional, but good to have if you want to run benchmarking with NCBench workflow.



```bash
conda create -n sarek_offline python=3.10 -y
conda activate sarek_offline
## install gsutil for downloading reference files from GATK bundle google cloud storage.
pip install gsutil
## install nextflow and snakemake
conda install -c conda-forge -c bioconda nextflow snakemake -y
```

## Step 2: Download Sarek Pipeline and Containers

### 2.1 Download Sarek Pipeline

- This guide is based on Singularity container system, you can adjust for other container system if needed.

- The current lastest stable version of Sarek is 3.5.1 (as of September, 2025).


```bash

mkdir -p container
export NXF_SINGULARITY_CACHEDIR=$PWD/container
export NXF_SINGULARITY_CACHE_DIR=$PWD/container  # some nf-core versions use this form

# nf-core pipelines download sarek \
#   --revision 3.5.1 \
#   --container-system singularity \
#   --compress none \
#   --container-cache-utilisation amend


nf-core pipelines download sarek \
  --revision 3.5.1 \
  --container-system singularity \
  --compress none \
  --container-cache-utilisation amend \
  --outdir $PWD/nf_sarek

```


## 2.2 Fix container symlinks for compatibility

This step may be redundant, but just to make sure the container images are correctly set up because later we will move all files on a different HPC without internet access so soft link may not work as expected (I have this bugs and this is my solution).

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

To able running GATK tools, you need to download the reference files from GATK bundle google cloud storage.
We will download the reference files for hg38 assembly, you can adjust for other assemblies if needed.

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
awk 'BEGIN{OFS="\t"}{print $1,0,$2}' gatk_hg38/Homo_sapiens_assembly38.fasta.fai \
  | grep -E '^(chr)?([0-9]+|X|Y|M|MT)$' \
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

You may check you directory structure now:

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

I have prepare `offline_hg38_template.config` that is the teamplate to enable cusomized local reference files, and also adapt to run on Saga of sigma2 and TSD HPC of UiO.

For our group users, you just need to run to generate: `offline_hg38.config`

```bash
sed "s|/PATH/TO/|$PWD/|g" offline_hg38_template.config > offline_hg38.config
```



For external users, you need to change the profile section and params section in `offline_hg38_template.config` to fit your environment.



## 5 Testing the pipeline with small data:

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

Create a sample sheet for the test data, this command is to replace the path in the sample sheet template to your current working directory.

```sh
sed "s|/PATH/TO/|$PWD/|g" samplesheet.csv > samplesheet_fixed.csv
```

You can now check the sructure of your working directory, it should look like this:

```sh
tree -L 1 

# .
# ├── 1.run_test_saga.sh
# ├── CITATIONS.md
# ├── container
# ├── gatk_hg38
# ├── LICENSE
# ├── nf_sarek
# ├── offline_hg38.config
# ├── offline_hg38_template.config
# ├── README.md
# ├── samplesheet.csv
# ├── samplesheet_fixed.csv
# └── test_data

```

## 6 Running the pipeline on your HPC

for saga users, you can submit the job with:

```sh
sbatch 1.run_test_saga.sh
```

For other HPC users, you can run the pipeline with
```sh
## optional to load modules if needed
# module load Nextflow/24.04.2

export SINGULARITY_CACHEDIR=$PWD/container
export NXF_SINGULARITY_CACHEDIR=PWD/container ## some nf-core versions use this form


nextflow run nf_sarek/3_5_1 -offline \
  -profile singularity,saga \
  -c offline_hg38.config \
  --input $PWD/samplesheet_fixed.csv \
  --genome HG38_OFFLINE \
  --tools manta,cnvkit,haplotypecaller,deepvariant \
  --outdir results_sarek_offline_test \
  -resume

```    

If the pipeline runs without error, you can check results in the `results_sarek_offline_test` folder.

## References

- [nf-core Sarek documentation](https://nf-co.re/sarek)
- [Nextflow documentation](https://www.nextflow.io/docs/latest/index.html)



