"""
This part of the workflow creates additonal annotations for the reference tree
of the Nextclade dataset.

REQUIRED INPUTS:

    metadata            = data/metadata.tsv
    prepared_sequences  = results/prepared_sequences.fasta
    tree                = results/tree.nwk

OUTPUTS:

    nt_muts     = results/nt_muts.json
    aa_muts     = results/aa_muts.json
    clades      = results/clades.json

This part of the workflow usually includes the following steps:

    - augur ancestral
    - augur translate
    - augur clades

See Augur's usage docs for these commands for more details.
"""

rule ancestral:
    """Reconstructing ancestral sequences and mutations"""
    input:
        tree = "results/{build}/tree.nwk",
        alignment = "results/{build}/aligned.fasta",
        root_sequence = config['ancestral']['root_sequence'],
        annotation = config['ancestral']['annotation'],
    output:
        node_data = "results/{build}/muts.json",
    log:
        "logs/{build}/ancestral.txt",
    benchmark:
        "benchmarks/{build}/ancestral.txt",
    params:
        inference = config["ancestral"]["inference"],
        translations = "results/{build}/translations",
        genes = lambda w: ' '.join(config['ancestral']['genes']),
    shell:
        r"""
        exec &> >(tee {log:q})

        augur ancestral \
            --tree {input.tree:q} \
            --alignment {input.alignment:q} \
            --annotation {input.annotation:q} \
            --translations {params.translations:q}/gene.%GENE.fasta \
            --genes {params.genes} \
            --output-node-data {output.node_data:q} \
            --root-sequence {input.root_sequence} \
            --inference {params.inference:q}
        """

rule traits:
    """
    Inferring ancestral traits for {params.columns!s}
      - increase uncertainty of reconstruction by {params.sampling_bias_correction} to partially account for sampling bias
    """
    input:
        tree = "results/{build}/tree.nwk",
        metadata = "results/{build}/metadata.tsv",
    output:
        node_data = "results/{build}/traits.json",
    log:
        "logs/{build}/traits.txt",
    benchmark:
        "benchmarks/{build}/traits.txt",
    params:
        columns = lambda wildcard: config['traits'][wildcard.build],
        sampling_bias_correction = config["traits"]["sampling_bias_correction"],
        strain_id = config.get("strain_id_field", "strain"),
    shell:
        r"""
        exec &> >(tee {log:q})

        augur traits \
            --tree {input.tree:q} \
            --metadata {input.metadata:q} \
            --metadata-id-columns {params.strain_id:q} \
            --output {output.node_data:q} \
            --columns {params.columns} \
            --confidence \
            --sampling-bias-correction {params.sampling_bias_correction:q}
        """
