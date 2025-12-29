#!/usr/bin/env python3
import os
import re
import sys
import argparse
from pathlib import Path
import csv

def parse_fastq_filename(filename):
    """
    Parse FASTQ filename to extract sample information.
    Expected format: <sample_id>_<run_id>_<lane_id>_<read>_<number>.fastq.gz
    """
    if filename.endswith('.fastq.gz'):
        base = filename.replace('.fastq.gz', '')
    elif filename.endswith('.fq.gz'):
        base = filename.replace('.fq.gz', '')
    else:
        raise ValueError("Filename must end with .fastq.gz or .fq.gz")

    tokens = base.split('_')

    if len(tokens) >= 4:
        patient_id = tokens[0]
        subsample = tokens[1]
        lane = tokens[2]
        read = tokens[3]
        sample_id = f"{patient_id}_{subsample}"

        return {
            'patient': patient_id,
            'sample': sample_id,
            'lane': lane,
            'read': read
        }
    return None

def generate_sarek_input(fastq_dir, output_csv='sarek_input.csv'):
    """
    Generate Sarek pipeline input CSV from directory of FASTQ files.

    Args:
        fastq_dir: Path to directory containing FASTQ files
        output_csv: Output CSV filename
    """
    fastq_dir = Path(fastq_dir)

    if not fastq_dir.exists():
        print(f"Error: Directory {fastq_dir} does not exist!")
        sys.exit(1)

    r1_files = sorted(fastq_dir.glob('*_R1_*.fastq.gz'))

    if not r1_files:
        print(f"Error: No R1 FASTQ files found in {fastq_dir}")
        sys.exit(1)

    samples = []

    for r1_file in r1_files:
        r1_info = parse_fastq_filename(r1_file.name)

        if not r1_info:
            print(f"Warning: Could not parse {r1_file.name}, skipping...")
            continue

        r2_pattern = r1_file.name.replace('_R1_', '_R2_')
        r2_file = fastq_dir / r2_pattern

        if not r2_file.exists():
            print(f"Warning: R2 file not found for {r1_file.name}, skipping...")
            continue

        sample_entry = {
            'patient': r1_info['patient'],
            'sample': r1_info['sample'],
            'lane': r1_info['lane'],
            'fastq_1': str(r1_file.absolute()),
            'fastq_2': str(r2_file.absolute())
        }

        samples.append(sample_entry)

    if samples:
        with open(output_csv, 'w', newline='') as csvfile:
            fieldnames = ['patient', 'sample', 'lane', 'fastq_1', 'fastq_2']
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)

            writer.writeheader()
            for sample in samples:
                writer.writerow(sample)

        print(f"Successfully generated {output_csv}")
        print(f"Total entries: {len(samples)}")
        print(f"Unique patients: {len(set(s['patient'] for s in samples))}")
        print(f"Unique samples: {len(set(s['sample'] for s in samples))}")
    else:
        print("Error: No valid FASTQ pairs found!")
        sys.exit(1)

def main():
    parser = argparse.ArgumentParser(
        description='Generate Sarek pipeline input CSV from FASTQ directory',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
        Example usage:
        %(prog)s -i /path/to/fastq/directory -o sarek_input.csv
        %(prog)s --input-dir ./fastq_files --output sarek_samples.csv
        """
    )

    parser.add_argument(
        '-i', '--input-dir',
        required=True,
        help='Directory containing FASTQ files'
    )

    parser.add_argument(
        '-o', '--output',
        default='sarek_input.csv',
        help='Output CSV filename (default: sarek_input.csv)'
    )

    args = parser.parse_args()

    generate_sarek_input(args.input_dir, args.output)

if __name__ == "__main__":
    main()
