#!/usr/bin/env python3

import csv
import argparse

def parse_args():
    parser = argparse.ArgumentParser(
        description="If clade_membership is empty, fill with MuV_genotype value",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument(
        "--input-metadata",
        type=str,
        required=True,
        help="Path to input metadata TSV file",
    )
    parser.add_argument(
        "--output-metadata",
        type=str,
        required=True,
        help="Path to output metadata TSV file",
    )
    return parser.parse_args()

def fill_clade_membership(input_path, output_path):
    with open(input_path, newline='', encoding='utf-8') as infile, \
         open(output_path, 'w', newline='', encoding='utf-8') as outfile:

        reader = csv.DictReader(infile, delimiter='\t')
        fieldnames = reader.fieldnames

        if 'clade_membership' not in fieldnames or 'MuV_genotype' not in fieldnames:
            raise ValueError("Input file must contain 'clade_membership' and 'MuV_genotype' columns")

        writer = csv.DictWriter(outfile, fieldnames=fieldnames, delimiter='\t')
        writer.writeheader()

        for row in reader:
            if row.get('clade_membership', '').strip() == '':
                row['clade_membership'] = row.get('MuV_genotype', '')
            writer.writerow(row)

def main():
    args = parse_args()
    fill_clade_membership(args.input_metadata, args.output_metadata)

if __name__ == '__main__':
    main()
