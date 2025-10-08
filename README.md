# Sarek 3.5.1: Fully Offline Setup Guide

This guide helps you set up and run the nf-core Sarek 3.5.1 pipeline offline on HPC with these tools: **manta, cnvkit, haplotypecaller, deepvariant.**

## Step 1: Prepare Your Environment

**Preprequisites**: singularity or apptainer must avaiable and callable on your systen/HPC.


Create a conda environment for downloading reference files, pipeline and containers.
You can skip this step if you already have Nextflow and gsutil installed.



```bash
conda create -n sarek_offline python=3.10 -y
conda activate sarek_offline
pip install gsutil
conda install -c conda-forge nextflow -y

```

## Step 2:



- Install Nextflow (tested 24.04.2)
- Ensure Singularity/Apptainer is available
- Install Python 3.10 (for gsutil) for downloading reference files from GATK bundle google cloud storage.
- Know your SLURM account (if needed to run jobs)


## Step 2: Download Containers and Reference Files

Check the `offline_setup.sh` script to download all necessary containers and reference files, I have used it to set up the environment on my HPC. All you need to do is adjust the paths inside the script and run it. NB: this script is not desgin to run directly without modification, and you must have internet access for this step.


This script supports:
- Download Sarek 3.5.1 containers for Singularity
- Fix container symlinks for compatibility
- Download all required reference files for hg38 (FASTA, FAI, dict, VCFs, etc.)
- Create a BED file (`noALT.bed`) for intervals

**Note:** You may need to activate a Python 3.10 environment for `gsutil`:
```bash
conda create -n gsutil_env python=3.10 -y
conda activate gsutil_env
pip install gsutil
```

---

## Step 3: Customize Your offline_hg38.config

The file `offline_hg38.config` defines the offline HPC setting, genome resources and intervals. 

**You must update all file paths to match your cluster's directory structure.**



Example section:
```groovy

// profile setup, our profile name is saga, you will see it later in running section
profiles {
  saga {                             // can change the name
    executor.name        = 'slurm'   // can change the scheduler
    executor.account     = 'nn9114k' // your slurm account

    singularity.enabled     = true
    singularity.autoMounts  = true
    singularity.pullTimeout = '10h'
    docker.enabled          = false
    podman.enabled          = false
    shifter.enabled         = false
    charliecloud.enabled    = false
    conda.enabled           = false
  }
}

// offline genome database
params {
	intervals = "/your/path/to/noALT.bed"
	genomes {
		'HG38_OFFLINE' {
			fasta        = "/your/path/to/Homo_sapiens_assembly38.fasta"
			fai          = "/your/path/to/Homo_sapiens_assembly38.fasta.fai"
			dict         = "/your/path/to/Homo_sapiens_assembly38.dict"
			dbsnp        = "/your/path/to/Homo_sapiens_assembly38.dbsnp138.vcf.gz"
			known_indels = "/your/path/to/Homo_sapiens_assembly38.known_indels.vcf.gz"
			known_snps   = "/your/path/to/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz"
			germline_resource = "/your/path/to/af-only-gnomad.hg38.vcf.gz"
		}
	}
}
```
**NEED to change all `/your/path/to/` entries to the correct absolute paths on your HPC.**

---

## Step 4: Prepare Your Sample Sheet

Create or update your sample sheet (CSV format) as required by Sarek. Example path:
```
/your/path/to/samplesheet.csv
```

---

## Step 5: Run the Pipeline Offline

Use the provided SLURM script (`1.test_sample.sh`) as a template. **Edit the SLURM account and username to match your environment.**

Example SLURM header:
```bash
#SBATCH --account=your_account_name
#SBATCH --job-name=sarek_offline
#SBATCH --output=sarek_offline-%j.out
```

Set the correct container cache paths:
NB: similar to DIR set up in `offline_setup.sh`, this set up make nextflow knows where the containers are located.

```bash
export SINGULARITY_CACHEDIR=/your/path/to/container
export NXF_SINGULARITY_CACHEDIR=/your/path/to/container
```

Run Nextflow:
NB: profile `saga` is used for our setup, adjust for your case, please check again the `offline_hg38.config`

```bash
nextflow run main.nf -profile saga 
	-c offline_hg38.config \
	--input /your/path/to/samplesheet.csv \
	--genome HG38_OFFLINE \
	--tools manta,cnvkit,haplotypecaller,deepvariant \
	--outdir /your/path/to/results \
	-resume
```


## Tips for Customization

- **File Paths:** Always use absolute paths in your config and scripts.
- **SLURM Account/Username:** Update SLURM directives to match your cluster's requirements.
- **Permissions:** Ensure you have read/write access to all directories.
- **Offline Operation:** No internet connection is required after setup; all resources are local.

---

## Troubleshooting

- Double-check all paths in `offline_hg38.config` and SLURM scripts.
- Make sure containers and reference files exist in the specified locations.
- If you encounter permission issues, check file and directory permissions.
- For Nextflow or Singularity errors, consult your HPC documentation or contact your system administrator.


## References

- [nf-core Sarek documentation](https://nf-co.re/sarek)
- [Nextflow documentation](https://www.nextflow.io/docs/latest/index.html)



