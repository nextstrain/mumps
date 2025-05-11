"""
This part of the workflow constructs the reference tree for the Nextclade dataset

REQUIRED INPUTS:

    metadata            = data/metadata.tsv
    prepared_sequences  = results/prepared_sequences.fasta

OUTPUTS:

    tree            = results/tree.nwk
    branch_lengths  = results/branch_lengths.json

This part of the workflow usually includes the following steps:

    - augur tree
    - augur refine

See Augur's usage docs for these commands for more details.
"""


rule tree:
    """Building tree"""
    input:
        alignment = "results/{build}/aligned.fasta"
    output:
        tree = "results/{build}/tree_raw.nwk",
    log:
        "logs/{build}/tree.txt",
    benchmark:
        "benchmarks/{build}/tree.txt",
    shell:
        r"""
        augur tree \
            --alignment {input.alignment:q} \
            --output {output.tree:q} 2>&1 | tee {log:q}
        """

rule refine:
    """
    Refining tree
      - estimate timetree
      - use {params.coalescent} coalescent timescale
      - estimate {params.date_inference} node dates
      - filter tips more than {params.clock_filter_iqd} IQDs from clock expectation
    """
    input:
        tree = "results/{build}/tree_raw.nwk",
        alignment = "results/{build}/aligned.fasta",
        metadata = "results/{build}/metadata.tsv",
    output:
        tree = "results/{build}/tree.nwk",
        node_data = "results/{build}/branch_lengths.json",
    log:
        "logs/{build}/refine.txt",
    benchmark:
        "benchmarks/{build}/refine.txt",
    params:
        refine_params = '--root mid_point',
        strain_id = config.get("strain_id_field", "strain"),
    shell:
        r"""
        augur refine \
            --tree {input.tree:q} \
            --alignment {input.alignment:q} \
            --metadata {input.metadata:q} \
            --metadata-id-columns {params.strain_id:q} \
            --output-tree {output.tree:q} \
            --output-node-data {output.node_data:q} \
            {params.refine_params} 2>&1 | tee {log:q}
        """
