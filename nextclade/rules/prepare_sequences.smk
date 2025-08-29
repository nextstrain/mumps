"""
This part of the workflow prepares sequences for constructing the reference tree
of the Nextclade dataset.

REQUIRED INPUTS:

    metadata    = data/metadata.tsv
    sequences   = data/sequences.fasta
    reference   = ../shared/reference.fasta

OUTPUTS:

    prepared_sequences = results/prepared_sequences.fasta

This part of the workflow usually includes the following steps:

    - augur index
    - augur filter
    - nextclade run
    - augur mask

See Nextclade's and Augur's usage docs for these commands for more details.
"""

rule align:
    """
    Aligning sequences to {input.reference}
      - filling gaps with N
    """
    input:
        sequences = "results/{build}/filtered.fasta",
        annotation = resolve_config_path(config['assemble_dataset']['annotation']),
        pathogen_json = resolve_config_path(config['assemble_dataset']['pathogen_json']),
        reference = resolve_config_path(config['assemble_dataset']['reference']),
    output:
        alignment = "results/{build}/aligned.fasta",
    log:
        "logs/{build}/align.txt",
    benchmark:
        "benchmarks/{build}/align.txt",
    params:
        translations = "results/{build}/translations",
    shell:
        r"""
        exec &> >(tee {log:q})

        nextclade run \
            --input-ref {input.reference:q} \
            --input-annotation {input.annotation:q} \
            --output-fasta {output.alignment:q} \
            --input-pathogen-json {input.pathogen_json:q} \
            --output-translations {params.translations:q}/gene.{{cds}}.fasta \
            {input.sequences:q}
        """
