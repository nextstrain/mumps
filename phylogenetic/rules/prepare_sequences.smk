"""
This part of the workflow prepares sequences for constructing the phylogenetic tree.

REQUIRED INPUTS:

    metadata    = data/metadata.tsv
    sequences   = data/sequences.fasta
    reference   = (from config)

OUTPUTS:

    metadata  = results/{build}/filtered.tsv
    alignment = results/{build}/aligned.fasta

This part of the workflow usually includes the following steps:

    - augur index
    - augur filter
    - augur align
    - augur mask

See Augur's usage docs for these commands for more details.
"""

rule filter:
    """
    Filtering sequences
    """
    input:
        sequences = "results/sequences.fasta",
        metadata = "results/metadata.tsv",
        exclude = resolve_config_path(config["filter"]["exclude"]),
        include = resolve_config_path(config["filter"]["include"]),
    output:
        sequences = "results/{build}/filtered.fasta",
        metadata = "results/{build}/filtered.tsv",
    log:
        "logs/{build}/filtered.txt",
    benchmark:
        "benchmarks/{build}/filtered.txt",
    params:
        args = lambda w: config['filter'][w.build],
        strain_id = config.get("strain_id_field", "strain"),
    shell:
        r"""
        exec &> >(tee {log:q})

        augur filter \
            --sequences {input.sequences:q} \
            --metadata {input.metadata:q} \
            --metadata-id-columns {params.strain_id:q} \
            --exclude {input.exclude:q} \
            --include {input.include:q} \
            --output-sequences {output.sequences:q} \
            --output-metadata {output.metadata:q} \
            {params.args}
        """

rule align:
    """
    Aligning sequences to {input.reference}
      - filling gaps with N
    """
    input:
        sequences = "results/{build}/filtered.fasta",
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