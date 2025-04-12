#! /usr/bin/env python3
"""
From stdin and if division or MuV_genotype is empty, attempt to parse division or genotype from mumps strain name.

Outputs the modified record to stdout.
"""

import argparse
import json
from sys import stdin, stdout, stderr
import re

# General list of country codes
COUNTRY_CODES = [
    'BIH', 'BRA', 'CAN', 'CHN', 'ES', 'ESP', 'ESP', 'GBR', 'IND', 'INDIA',
    'IRQ', 'ITA', 'JPN', 'KOR', 'MEX', 'NLD', 'NLD', 'NOR', 'PAK', 'RUS',
    'SRB', 'SWE', 'TWN', 'TWN', 'USA', 'VNM'
]

def parse_args():
    parser = argparse.ArgumentParser(
        description="If division or MuV_genotype is empty, attempt to parse division and MuV_genotype from strain name.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument("--strain-field", default='strain',
        help="Strain field from which the division should be parsed.")
    parser.add_argument("--division-field", default='division',
        help="Division field to which the parsed division should be saved.")
    parser.add_argument("--genotype-field", default='MuV_genotype',
        help="MuV_genotype field to which the parsed genotype should be saved.")

    return parser.parse_args()

def _parse_division_from_strain(record, strain_field):
    strain = record.get(strain_field, '')
    division_field = ''

    # Expand pattern with list of country codes
    pattern = rf"MuV[siS]/([^/0-9.]+)\.({'|'.join(COUNTRY_CODES)})/[0-9]{{1,2}}\.[0-9]{{2}}"
    # Examples:
    # Parse division 'Manitoba' from 'MuVs/Manitoba.CAN/17.17/5[G]'
    # Parse division 'Ontario' from 'MuVi/Ontario.CAN/12.17/3[G]'
    # Parse division 'Boras' from 'MuVs/Boras.SWE/2.20[G]'
    # Avoid parsing: '14778' from 'MuVs/14778.SWE/0.06[G]
    if re.match(pattern, strain):
        match = re.match(pattern, strain)
        division_field = match.group(1)

    # Parse "NewYork" from 'MuVs/NewYork.USA/2019/38854'
    # MuVs/NewYork.USA/2017/51025
    if re.match(r'MuV[siS]/([^/0-9.]+)\.USA/', strain):
        match = re.match(r'MuV[siS]/([^/0-9.]+)\.USA/', strain)
        division_field = match.group(1)

    # Parse "Indiana" from 'MuVs/Indiana_USA/201738605'
    if re.match(r'MuV[siS]/([^/0-9.]+)_USA/', strain):
        match = re.match(r'MuV[siS]/([^/0-9.]+)_USA/', strain)
        division_field = match.group(1)

    # Parse "Okinawa" from "MuVi/Okinawa50.JPN/29.15[G]"
    if re.match(r'MuV[siS]/([^/0-9.]+)[0-9]+\.JPN/', strain):
        match = re.match(r'MuV[siS]/([^/0-9.]+)[0-9]+\.JPN/', strain)
        division_field = match.group(1)

    return division_field

def _parse_genotype_from_strain(record, strain_field):
    strain = record.get(strain_field, '')
    genotype_field = ''

    if re.search(r'\[([A-Z])\]$', strain):
        match = re.search(r'\[([A-Z])\]$', strain)
        genotype_field = match.group(1)

    return genotype_field

def main():
    args = parse_args()

    for index, record in enumerate(stdin):
        record = json.loads(record)
        if not record[args.division_field]:
            record[args.division_field] = _parse_division_from_strain(record, args.strain_field)
        if not record[args.genotype_field]:
            record[args.genotype_field] = _parse_genotype_from_strain(record, args.strain_field)

        stdout.write(json.dumps(record) + "\n")


if __name__ == "__main__":
    main()
