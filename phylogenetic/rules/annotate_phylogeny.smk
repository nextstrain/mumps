"""
This part of the workflow creates additonal annotations for the phylogenetic tree.

REQUIRED INPUTS:

    metadata   = results/{build}/filtered.tsv
    alignment  = results/{build}/aligned.fasta
    tree       = results/{build}/tree.nwk

OUTPUTS:

    node_data = results/*.json

    There are no required outputs for this part of the workflow as it depends
    on which annotations are created. All outputs are expected to be node data
    JSON files that can be fed into `augur export`.

    See Nextstrain's data format docs for more details on node data JSONs:
    https://docs.nextstrain.org/page/reference/data-formats.html

This part of the workflow usually includes the following steps:

    - augur traits
    - augur ancestral
    - augur translate
    - augur clades

See Augur's usage docs for these commands for more details.

Custom node data files can also be produced by build-specific scripts in addition
to the ones produced by Augur commands.
"""


rule ancestral:
    """Reconstructing ancestral sequences and mutations"""
    input:
        tree = "results/{build}/tree.nwk",
        alignment = "results/{build}/aligned.fasta",
    output:
        node_data = "results/{build}/nt_muts.json",
    log:
        "logs/{build}/ancestral.txt",
    benchmark:
        "benchmarks/{build}/ancestral.txt",
    params:
        inference = config["ancestral"]["inference"],
    shell:
        r"""
        exec &> >(tee {log:q})

        augur ancestral \
            --tree {input.tree:q} \
            --alignment {input.alignment:q} \
            --output-node-data {output.node_data:q} \
            --inference {params.inference:q}
        """

rule translate:
    """Translating amino acid sequences"""
    input:
        tree = "results/{build}/tree.nwk",
        node_data = "results/{build}/nt_muts.json",
        reference = resolve_config_path(config['reference']),
    output:
        node_data = "results/{build}/aa_muts.json",
    log:
        "logs/{build}/translate.txt",
    benchmark:
        "benchmarks/{build}/translate.txt",
    shell:
        r"""
        exec &> >(tee {log:q})

        augur translate \
            --tree {input.tree:q} \
            --ancestral-sequences {input.node_data:q} \
            --reference-sequence {input.reference:q} \
            --output {output.node_data:q}
        """

rule traits:
    """
    Inferring ancestral traits for {params.columns!s}
      - increase uncertainty of reconstruction by {params.sampling_bias_correction} to partially account for sampling bias
    """
    input:
        tree = "results/{build}/tree.nwk",
        metadata = "results/{build}/filtered.tsv",
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
