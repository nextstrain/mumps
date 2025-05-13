"""
This part of the workflow prepares sequences for constructing the phylogenetic tree.

REQUIRED INPUTS:

    metadata    = data/metadata.tsv
    sequences   = data/sequences.fasta
    reference   = ../shared/reference.fasta

OUTPUTS:

    prepared_sequences = results/prepared_sequences.fasta

This part of the workflow usually includes the following steps:

    - augur index
    - augur filter
    - augur align
    - augur mask

See Augur's usage docs for these commands for more details.
"""


rule download:
    """Downloading sequences and metadata from data.nextstrain.org"""
    output:
        sequences = "data/sequences.fasta.zst",
        metadata = "data/metadata.tsv.zst"
    params:
        sequences_url = config["sequences_url"],
        metadata_url = config["metadata_url"],
    shell:
        """
        curl -fsSL --compressed {params.sequences_url:q} --output {output.sequences}
        curl -fsSL --compressed {params.metadata_url:q} --output {output.metadata}
        """

rule decompress:
    """Decompressing sequences and metadata"""
    input:
        sequences = "data/sequences.fasta.zst",
        metadata = "data/metadata.tsv.zst"
    output:
        sequences = "data/sequences.fasta",
        metadata = "data/metadata.tsv"
    shell:
        """
        zstd -d -c {input.sequences} > {output.sequences}
        zstd -d -c {input.metadata} > {output.metadata}
        """

rule merge_annotations:
    """Merge identical sequence annotations"""
    input:
        metadata = "data/metadata.tsv",
        identical = "defaults/sh/metadata_identical.tsv",
    output:
        merged_metadata = "data/metadata_merged.tsv",
    params:
        id_column = "accession",
    shell:
        r"""
        augur merge --metadata \
          a={input.metadata:q} \
          b={input.identical:q} \
          --metadata-id-columns {params.id_column} \
          --output-metadata {output.merged_metadata}
        """

rule filter:
    """
    Filtering to
      - various criteria based on the auspice JSON target
      - from {params.min_date} onwards
      - excluding strains in {input.exclude}
      - including strains in {input.include}
    """
    input:
        sequences = "data/sequences.fasta",
        metadata = "data/metadata.tsv",
        exclude = "defaults/{build}/exclude.txt",
        include = "defaults/{build}/include.txt"
    output:
        sequences = "results/{build}/filtered.fasta",
        metadata = "results/{build}/metadata.tsv",
    log:
        "logs/{build}/filtered.txt",
    benchmark:
        "benchmarks/{build}/filtered.txt",
    params:
        group_by = config['filter']['group_by'],
        filter_params = lambda wildcard: config['filter']['specific'][wildcard.build],
        strain_id = config.get("strain_id_field", "strain"),
    shell:
        r"""
        augur filter \
            --sequences {input.sequences:q} \
            --metadata {input.metadata:q} \
            --metadata-id-columns {params.strain_id:q} \
            --exclude {input.exclude:q} \
            --include {input.include:q} \
            --output {output.sequences:q} \
            --output-metadata {output.metadata:q} \
            --group-by {params.group_by} \
            {params.filter_params} 2>&1 | tee {log:q}
        """

ruleorder: filter_sh > filter

rule filter_sh:
    """
    Filtering to
      - various criteria based on the auspice JSON target
      - from {params.min_date} onwards
      - excluding strains in {input.exclude}
      - including strains in {input.include}
    """
    input:
        sequences = "data/sequences.fasta",
        metadata = "data/metadata.tsv",
        clade_membership = "defaults/sh/metadata_duplicate.txt",
        exclude = "defaults/sh/exclude.txt",
        include = "defaults/sh/include.txt"
    output:
        merged_metadata = "results/sh/metadata_merged.tsv",
        sequences = "results/sh/filtered.fasta",
        metadata = "results/sh/metadata.tsv",
    log:
        "logs/sh/filtered.txt",
    benchmark:
        "benchmarks/sh/filtered.txt",
    params:
        group_by = config['filter']['group_by'],
        filter_params = config['filter']['specific']['sh'],
        strain_id = config.get("strain_id_field", "strain"),
    shell:
        r"""
        augur merge \
        --metadata a={input.metadata:q} b={input.clade_membership:q} \
        --metadata-id-columns a={params.strain_id:q} b={params.strain_id:q} \
        --output-metadata {output.merged_metadata:q}

        augur filter \
            --sequences {input.sequences:q} \
            --metadata {output.merged_metadata:q} \
            --metadata-id-columns {params.strain_id:q} \
            --include {input.include:q} \
            --output-sequences {output.sequences:q} \
            --output-metadata {output.metadata:q} \
            {params.filter_params} 2>&1 | tee {log:q}
        """

rule align:
    """
    Aligning sequences to {input.reference}
      - filling gaps with N
    """
    input:
        sequences = "results/{build}/filtered.fasta",
        reference = lambda wildcard: config['reference'][wildcard.build],
    output:
        alignment = "results/{build}/aligned.fasta",
    log:
        "logs/{build}/align.txt",
    benchmark:
        "benchmarks/{build}/align.txt",
    shell:
        r"""
        augur align \
            --sequences {input.sequences:q} \
            --reference-sequence {input.reference:q} \
            --output {output.alignment:q} \
            --fill-gaps \
            --remove-reference 2>&1 | tee {log:q}
        """