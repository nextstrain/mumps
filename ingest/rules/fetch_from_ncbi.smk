"""
This part of the workflow handles fetching sequences and metadata from NCBI.

REQUIRED INPUTS:

    None

OUTPUTS:

    ndjson = data/ncbi.ndjson

There are two different approaches for fetching data from NCBI.
Choose the one that works best for the pathogen data and edit the workflow config
to provide the correct parameter.

1. Fetch with NCBI Datasets (https://www.ncbi.nlm.nih.gov/datasets/)
    - requires `ncbi_taxon_id` config
    - Directly returns NDJSON without custom parsing
    - Fastest option for large datasets (e.g. SARS-CoV-2)
    - Only returns metadata fields that are available through NCBI Datasets
    - Only works for viral genomes

2. Fetch from Entrez (https://www.ncbi.nlm.nih.gov/books/NBK25501/)
    - requires `entrez_search_term` config
    - Returns all available data via a GenBank file
    - Requires a custom script to parse the necessary fields from the GenBank file
"""

###########################################################################
####################### 1. Fetch from NCBI Datasets #######################
###########################################################################


rule fetch_ncbi_dataset_package:
    params:
        ncbi_taxon_id=config["ncbi_taxon_id"],
    output:
        dataset_package=temp("data/ncbi_dataset.zip"),
    # Allow retries in case of network errors
    retries: 5
    benchmark:
        "benchmarks/fetch_ncbi_dataset_package.txt"
    shell:
        r"""
        datasets download virus genome taxon {params.ncbi_taxon_id:q} \
            --no-progressbar \
            --filename {output.dataset_package}
        """

# Note: This rule is not part of the default workflow!
# It is intended to be used as a specific target for users to be able
# to inspect and explore the full raw metadata from NCBI Datasets.
rule dump_ncbi_dataset_report:
    input:
        dataset_package="data/ncbi_dataset.zip",
    output:
        ncbi_dataset_tsv="data/ncbi_dataset_report_raw.tsv",
    shell:
        r"""
        dataformat tsv virus-genome \
            --package {input.dataset_package} > {output.ncbi_dataset_tsv}
        """


rule extract_ncbi_dataset_sequences:
    input:
        dataset_package="data/ncbi_dataset.zip",
    output:
        ncbi_dataset_sequences=temp("data/ncbi_dataset_sequences.fasta"),
    benchmark:
        "benchmarks/extract_ncbi_dataset_sequences.txt"
    shell:
        r"""
        unzip -jp {input.dataset_package} \
            ncbi_dataset/data/genomic.fna > {output.ncbi_dataset_sequences}
        """


rule format_ncbi_dataset_report:
    input:
        dataset_package="data/ncbi_dataset.zip",
    output:
        ncbi_dataset_tsv=temp("data/ncbi_dataset_report.tsv"),
    params:
        ncbi_datasets_fields=",".join(config["ncbi_datasets_fields"]),
    benchmark:
        "benchmarks/format_ncbi_dataset_report.txt"
    shell:
        r"""
        dataformat tsv virus-genome \
            --package {input.dataset_package} \
            --fields {params.ncbi_datasets_fields:q} \
            --elide-header \
            | csvtk fix-quotes -Ht \
            | csvtk add-header -t -n {params.ncbi_datasets_fields:q} \
            | csvtk rename -t -f accession -n accession_version \
            | csvtk -t mutate -f accession_version -n accession -p "^(.+?)\." --at 1 \
            > {output.ncbi_dataset_tsv}
        """


# Technically you can bypass this step and directly provide FASTA and TSV files
# as input files for the curate pipeline.
# We do the formatting here to have a uniform NDJSON file format for the raw
# data that we host on data.nextstrain.org
rule format_ncbi_datasets_ndjson:
    input:
        ncbi_dataset_sequences="data/ncbi_dataset_sequences.fasta",
        ncbi_dataset_tsv="data/ncbi_dataset_report_with_strain.tsv",
    output:
        ndjson="data/ncbi.ndjson",
    log:
        "logs/format_ncbi_datasets_ndjson.txt",
    benchmark:
        "benchmarks/format_ncbi_datasets_ndjson.txt"
    shell:
        r"""
        augur curate passthru \
            --metadata {input.ncbi_dataset_tsv} \
            --fasta {input.ncbi_dataset_sequences} \
            --seq-id-column accession_version \
            --seq-field sequence \
            --unmatched-reporting warn \
            --duplicate-reporting warn \
            2> {log} > {output.ndjson}
        """

###########################################################################
########################## 2. Fetch from Entrez ###########################
###########################################################################

rule fetch_from_ncbi_entrez:
    params:
        term=f'txid{config["ncbi_taxon_id"]}[Primary Organism]',
    output:
        genbank="data/genbank.gb",
    # Allow retries in case of network errors
    retries: 5
    log:
        "logs/fetch_from_ncbi_entrez.txt"
    benchmark:
        "benchmarks/fetch_from_ncbi_entrez.txt"
    shell:
        r"""
        vendored/fetch-from-ncbi-entrez \
            --term {params.term:q} \
            --output {output.genbank:q} \
        2>&1 | tee {log:q}
        """

rule genbank_to_json:
    input:
        genbank="data/genbank.gb",
    output:
        ndjson=temp("data/entrez.ndjson"),
    benchmark:
        "benchmarks/genbank_to_json.txt",
    log:
        "logs/genbank_to_json.txt",
    shell:
        r"""
        (bio json --lines {input.genbank:q} \
        > {output.ndjson:q} ) 2> {log:q}
        """

rule parse_strain:
    input:
        ndjson="data/entrez.ndjson",
    output:
        metadata="data/metadata_ncbi_entrez.tsv",
    benchmark:
        "benchmarks/parse_strain.txt",
    log:
        "logs/parse_strain.txt"
    shell:
        r"""
        ( cat {input.ndjson:q} \
        | jq -c '{{accession: .record.accessions[0], strain: .record.strain[0]}}' \
        | augur curate passthru \
            --output-metadata {output.metadata:q} ) \
        2>&1 | tee {log:q}
        """

rule merge_strain_name:
    input:
        ncbi_dataset="data/ncbi_dataset_report.tsv",
        ncbi_entrez="data/metadata_ncbi_entrez.tsv",
    output:
        metadata="data/ncbi_dataset_report_with_strain.tsv",
    log:
        "logs/merge_strain_name.txt"
    params:
        metadata_id='accession',
    shell:
        r"""
        augur merge \
          --metadata \
            datasets={input.ncbi_dataset:q} \
            entrez={input.ncbi_entrez:q} \
          --metadata-id-columns {params.metadata_id} \
          --output-metadata {output.metadata:q} \
          2>&1 | tee {log:q}
        """