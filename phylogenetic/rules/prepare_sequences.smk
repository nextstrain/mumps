"""
This part of the workflow prepares sequences for constructing the phylogenetic tree.

REQUIRED INPUTS:

    metadata    = data/metadata.tsv
    sequences   = data/sequences.fasta
    reference   = (from config)

OUTPUTS:

    metadata  = results/{build}/subsampled.tsv
    alignment = results/{build}/aligned.fasta

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

rule subsample:
    """
    Subsampling to
      - various criteria based on the auspice JSON target
      - from {params.min_date} onwards
      - excluding strains in {input.exclude}
      - including strains in {input.include}
      - minimum genome length of {params.min_length}
    """
    input:
        sequences = "data/sequences.fasta",
        metadata = "data/metadata.tsv",
        config = "results/run_config.yaml",
    output:
        sequences = "results/{build}/subsampled.fasta",
        metadata = "results/{build}/subsampled.tsv",
    log:
        "logs/{build}/subsample.txt",
    benchmark:
        "benchmarks/{build}/subsample.txt",
    params:
        config_section = lambda w: ["custom_subsample" if config.get("custom_subsample") else "subsample", w.build],
        strain_id = config.get("strain_id_field", "strain"),
    threads: workflow.cores
    shell:
        r"""
        exec &> >(tee {log:q})

        augur subsample \
            --sequences {input.sequences:q} \
            --metadata {input.metadata:q} \
            --metadata-id-columns {params.strain_id:q} \
            --config {input.config:q} \
            --config-section {params.config_section:q} \
            --nthreads {threads:q} \
            --output-sequences {output.sequences:q} \
            --output-metadata {output.metadata:q}
        """

rule align:
    """
    Aligning sequences to {input.reference}
      - filling gaps with N
    """
    input:
        sequences = "results/{build}/subsampled.fasta",
        reference = resolve_config_path(config['reference']),
    output:
        alignment = "results/{build}/aligned.fasta",
    log:
        "logs/{build}/align.txt",
    benchmark:
        "benchmarks/{build}/align.txt",
    shell:
        r"""
        exec &> >(tee {log:q})

        augur align \
            --sequences {input.sequences:q} \
            --reference-sequence {input.reference:q} \
            --output {output.alignment:q} \
            --fill-gaps \
            --remove-reference
        """