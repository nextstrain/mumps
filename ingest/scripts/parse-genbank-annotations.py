#!/usr/bin/env python3
# Original script from perl: https://github.com/j23414/basic-phylogenetic-pipeline/blob/main/bin/procGenbank.pl
# Auth: Converted to python and expanded with help by ChatGPT
# Prompts:
# (1) Convert to python, (2) Asked for generalized --annotation [list of annotation] flag, (3) Asked for explicitly passed local variables (not global)
# Cleanup:
# (1) Refactor parse_args to separate function, (2) Use more descriptive function and variable namaes, (3) Add some documentation
# Date: 2025/04/07

import sys
import re
import argparse

def parse_args():
    """
    Parse command line arguments.
    """
    parser = argparse.ArgumentParser(
        description="Parse GenBank file and extract selected annotations.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument(
        "input",
        help="GenBank input file"
    )
    parser.add_argument(
        "--annotation",
        type=lambda s: [a.strip() for a in s.split(",")],
        default=["strain"],
        help="Comma-separated list of annotation fields to extract (e.g., strain,isolate,serotype)"
    )
    parser.add_argument(
        "--fill-blank",
        default="-",
        help='Value to use when annotation is missing'
    )
    parser.add_argument(
        "--silent-no-match",
        action="store_true",
        help="Do not print entries where none of the annotations are found"
    )
    return parser.parse_args()


def print_entry(accession, annotation_values, annotations, na_value, silent):
    values = [annotation_values.get(ann, na_value) for ann in annotations]

    # Suppress output if all annotations are NA and --silent-no-match is set
    if silent and all(val == na_value for val in values):
        return

    print("\t".join([accession] + values))

def parse_genbank_annotations(file_handle, annotations, na_value, silent):
    accession = na_value
    annotation_values = {ann: na_value for ann in annotations}
    seq = -1

    print("\t".join(["accession"] + annotations))

    for line in file_handle:
        line = line.rstrip()

        if line.startswith("//"):
            print_entry(accession, annotation_values, annotations, na_value, silent)
            # Reset state
            accession = na_value
            annotation_values = {ann: na_value for ann in annotations}
            seq = -1

        elif seq > 0:
            # Ignore sequence section during pattern match
            continue

        else:
            match = re.match(r"ACCESSION\s+(\S+)", line)
            if match:
                accession = match.group(1)
                continue

            match = re.match(r"LOCUS\s+(\S+)", line)
            if match:
                accession = match.group(1)
                continue

            if line.startswith("ORIGIN"):
                # Start of sequence section
                seq = 1
                continue

            for ann in annotations:
                match = re.search(r'/{0}="(.+?)"'.format(re.escape(ann)), line)
                if match:
                    annotation_values[ann] = match.group(1)

def main():
    args = parse_args()

    try:
        with open(args.input, encoding="utf-8") as fh:
            parse_genbank_annotations(fh, args.annotation, args.fill_blank, args.silent_no_match)
    except IOError as e:
        sys.stderr.write(f"Could not open file '{args.input}': {e}\n")
        sys.exit(1)

if __name__ == "__main__":
    main()
