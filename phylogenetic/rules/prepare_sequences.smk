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
from augur.subsample import get_referenced_files

rule subsample:
    input:
        config = "results/{build}/subsample_config.yaml",
        sequences = "results/sequences.fasta",
        metadata = "results/metadata.tsv",
        referenced_files = lambda w: get_referenced_files(f"results/{w.build}/subsample_config.yaml"),
    output:
        sequences = "results/{build}/subsampled.fasta",
        metadata = "results/{build}/subsampled.tsv",
    log:
        "logs/{build}/subsample.txt",
    benchmark:
        "benchmarks/{build}/subsample.txt",
    params:
        strain_id = config.get("strain_id_field", "strain"),
    shell:
        r"""
        exec &> >(tee {log:q})

        augur subsample \
            --sequences {input.sequences:q} \
            --metadata {input.metadata:q} \
            --metadata-id-columns {params.strain_id:q} \
            --output-sequences {output.sequences:q} \
            --output-metadata {output.metadata:q} \
            --config {input.config}
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