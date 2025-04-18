#! /usr/bin/env python3
"""
From stdin and if division or MuV_genotype or date is empty, attempt to parse them from the mumps strain name.

Outputs the modified record to stdout.
"""

import argparse
import json
from sys import stdin, stdout, stderr
import re

# General list of country codes
COUNTRY_CODES = [
    'BIH', 'BRA', 'CAN', 'CHN', 'ES', 'ESP', 'GBR', 'IND', 'INDIA',
    'IRQ', 'ITA', 'JPN', 'KOR', 'MEX', 'NLD', 'NOR', 'PAK', 'RUS',
    'SRB', 'SWE', 'TWN', 'USA', 'VNM'
]

def parse_args():
    parser = argparse.ArgumentParser(
        description="If division or MuV_genotype or date is empty, attempt to parse them from the mumps strain name.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument("--strain-field", default='strain',
        help="Strain field from which the division should be parsed.")
    parser.add_argument("--division-field", default='division',
        help="Division field to which the parsed division should be saved.")
    parser.add_argument("--genotype-field", default='MuV_genotype',
        help="MuV_genotype field to which the parsed genotype should be saved.")
    parser.add_argument("--date-field", default='date',
        help="Date field to which the parsed year should be saved.")

    return parser.parse_args()

def _parse_division_from_strain(record, strain_field):
    strain = record.get(strain_field, '')
    division_field = ''

    # Expand pattern with list of country codes
    pattern = re.compile(rf"MuV[siS]/([^/0-9.]+)\.({'|'.join(COUNTRY_CODES)})/[0-9]{{1,2}}\.[0-9]{{2}}")
    # Examples:
    # Parse division 'Manitoba' from 'MuVs/Manitoba.CAN/17.17/5[G]'
    # Parse division 'Ontario' from 'MuVi/Ontario.CAN/12.17/3[G]'
    # Parse division 'Boras' from 'MuVs/Boras.SWE/2.20[G]'
    # Avoid parsing: '14778' from 'MuVs/14778.SWE/0.06[G]
    if match:= pattern.match(strain):
        division_field = match.group(1)

    # Parse "NewYork" from 'MuVs/NewYork.USA/2019/38854'
    # MuVs/NewYork.USA/2017/51025
    pattern_usa_division = re.compile(r'MuV[siS]/([^/0-9.]+)\.USA/')
    if match := pattern_usa_division.match(strain):
        division_field = match.group(1)

    # Parse "Indiana" from 'MuVs/Indiana_USA/201738605'
    pattern_usa_with_underscores = re.compile(r'MuV[siS]/([^/0-9.]+)_USA/')
    if match:= pattern_usa_with_underscores.match(strain):
        division_field = match.group(1)

    # Parse "Okinawa" from "MuVi/Okinawa50.JPN/29.15[G]"
    pattern_japan_with_digits = re.compile(r'MuV[siS]/([^/0-9.#]+)[#]?[A-Z]?[0-9]+\.JPN/')
    if match:= pattern_japan_with_digits.match(strain):
        division_field = match.group(1)

    return division_field

def _parse_genotype_from_strain(record, strain_field):
    strain = record.get(strain_field, '')
    genotype_field = ''

    pattern_genotype = re.compile(r'\[([A-Z][0-9]?)\]$')
    pattern_genotype_slash = re.compile(r'\[([A-Z][0-9]?/[A-Z][0-9]?)\]$')

    if match:= pattern_genotype.search(strain):
        genotype_field = match.group(1)
    elif match:= pattern_genotype_slash.search(strain):
        genotype_field = match.group(1)

    return genotype_field

def _parse_date_from_strain(record, strain_field):
    strain = record.get(strain_field, '')
    date_field = 'XXXX-XX-XX'

    # Expand pattern with list of country codes
    pattern_year = re.compile(rf"MuV[siS]/[^/]+\.({'|'.join(COUNTRY_CODES)})/[0-9]{{1,2}}\.([0-9]{{2}})")
    # Examples:
    # Parse year '2017' from 'MuVs/Manitoba.CAN/17.17/5[G]'
    # Parse year '2006' from 'MuVs/14778.SWE/0.06[G]
    if match:= pattern_year.match(strain):
        year_suffix = int(match.group(2))
        # TODO: The 30 threshhold will need to be revisited in year 2030
        if year_suffix > 30:
            date_field = f"19{year_suffix:02d}-XX-XX"
        else:
            date_field = f"20{year_suffix:02d}-XX-XX"

    return date_field

def main():
    args = parse_args()

    for index, record in enumerate(stdin):
        record = json.loads(record)
        if not record[args.division_field]:
            record[args.division_field] = _parse_division_from_strain(record, args.strain_field)
        if not record[args.genotype_field]:
            record[args.genotype_field] = _parse_genotype_from_strain(record, args.strain_field)
        if record[args.date_field] == "XXXX-XX-XX":
            record[args.date_field] = _parse_date_from_strain(record, args.strain_field)

        stdout.write(json.dumps(record) + "\n")


if __name__ == "__main__":
    main()
