#!/usr/bin/env python3
# Auth: Jennifer
# Date: 2018/05/14 bash script, 2025/04/21 python refactor

import os
import sys
import time
import argparse
import requests
from pathlib import Path

def parse_args():
    """
    Parse command line arguments.
    """
    parser = argparse.ArgumentParser(
        description="Batch fetch GenBank records from NCBI.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument(
        "--ids",
        required=True,
        help="File with GenBank IDs (one per line)"
    )
    parser.add_argument(
        "--batchsize",
        type=int,
        default=100,
        help="Number of IDs to fetch per request"
    )
    parser.add_argument(
        "--cache-dir",
        default="gb",
        help="Directory to cache temporary batched GenBank files"
    )
    parser.add_argument(
        "--output-genbank",
        help="Output file to write results"
    )
    parser.add_argument(
        "--stdout",
        action="store_true",
        help="Write GenBank output to stdout instead of file"
    )
    return parser.parse_args()

def fetch_genbanks(id_list, cache_dir, output_handle, batch_size=100):
    cache_path = Path(cache_dir)
    cache_path.mkdir(exist_ok=True)

    total_ids = len(id_list)
    file_index = batch_size
    current_batch = []
    all_gb_files = []

    def fetch_and_save(batch_ids, file_num):
        batch_str = ",".join(batch_ids)
        out_path = cache_path / f"{file_num}.gb"
        # Checking if the batched file already exists allows us to continue downloading a series of batched files, without having to restart
        if not out_path.exists():
            print(f"===== Fetching {file_num - batch_size + 1} to {min(file_num, total_ids)} of {total_ids} total Genbank IDs", file=sys.stderr)
            time.sleep(1)
            url = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi"
            params = {
                "db": "nuccore",
                "id": batch_str,
                "rettype": "gb",
                "retmode": "text"
            }
            headers = {
                "User-Agent": "Python Script (hello@nextstrain.org)"
            }
            r = requests.get(url, params=params, headers=headers)
            r.raise_for_status()
            out_path.write_text(r.text)
        else:
             print(f"===== Using cache from {out_path} for {file_num - batch_size + 1} to {min(file_num, total_ids)} of {total_ids} total Genbank IDs", file=sys.stderr)
        return out_path

    for i, genbank_id in enumerate(id_list):
        if genbank_id.strip() == "":
            continue
        current_batch.append(genbank_id.strip())
        if len(current_batch) == batch_size:
            gb_file = fetch_and_save(current_batch, file_index)
            all_gb_files.append(gb_file)
            current_batch = []
            file_index += batch_size

    # Final batch
    if current_batch:
        gb_file = fetch_and_save(current_batch, file_index)
        all_gb_files.append(gb_file)

    # Output results
    for gb_file in sorted(all_gb_files):
        with open(gb_file, "r", encoding='utf-8') as f:
            output_handle.write(f.read())

    # Cleanup
    for gb_file in cache_path.glob("*.gb"):
        gb_file.unlink()
    cache_path.rmdir()


def main():
    args = parse_args()

    with open(args.ids, "r", encoding='utf-8') as f:
        id_list = [line.strip() for line in f if line.strip()]

    if args.stdout or not args.output_genbank:
        fetch_genbanks(id_list, args.cache_dir, sys.stdout, batch_size=args.batchsize)
    else:
        with open(args.output_genbank, "w", encoding='utf-8') as out_f:
            fetch_genbanks(id_list, args.cache_dir, out_f, batch_size=args.batchsize)


if __name__ == "__main__":
    main()
