# This is helper README for setting up Sarek WGS pipeline in TSD, applying to wgs data of autisism samples.



## helper scripts for generating input csv files

Example command to generate input csv file for Sarek WGS pipeline:

```sh

module purge
module load Python/3.12.3-GCCcore-13.3.0
module load Java/17.0.6


TAG=240425_LH00534.A.Project_Djurovic-DNA1-2024-03-01

python3 scripts/generate_sarek_input.py \
  -i "/cluster/projects/p33/users/alexeas/wgs/from_marius/${TAG}/fastq" \
  -o ${TAG}.csv

```

NOTE: it is assumed that the fastq files are named in the following format:

```<sample_id>_<run_id>_<lane_id>_<read>_<number>.fastq.gz```
For example: ```240425_s1_L001_R1_001.fastq.gz```

where:
- sample_id: 240425
- run_id: s1
- lane_id: L001
- read: R1 or R2
- number: 001

## Running Sarek WGS pipeline in TSD

Since the data is already stored in TSD, you can directly run the Sarek WGS pipeline using the generated csv file as input.


```sh

cd /cluster/projects/p33/users/datn/nextflow_runs/sarek_offline
sbatch 3.run_autism_1.sh

```

This script is to run only a subset of samples in `/cluster/projects/p33/users/alexeas/wgs/from_marius/240425_LH00534.A.Project_Djurovic-DNA1-2024-03-01/fastq` for testing purpose. 


You can modify the script to run all samples or other input directories based on the provided template in `3.run_autism_1.sh`.