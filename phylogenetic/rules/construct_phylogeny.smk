"""
This part of the workflow constructs the phylogenetic tree.

REQUIRED INPUTS:

    metadata   = results/{build}/filtered.tsv
    alignment  = results/{build}/aligned.fasta

OUTPUTS:

    tree            = results/{build}/tree_raw.nwk
    branch_lengths  = results/{build}/branch_lengths.json

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
        exec &> >(tee {log:q})

        augur tree \
            --alignment {input.alignment:q} \
            --output {output.tree:q}
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
        metadata = "results/{build}/filtered.tsv"
    output:
        tree = "results/{build}/tree.nwk",
        node_data = "results/{build}/branch_lengths.json",
    log:
        "logs/{build}/refine.txt",
    benchmark:
        "benchmarks/{build}/refine.txt",
    params:
        coalescent = lambda w: conditional("--coalescent", config["refine"][w.build].get("coalescent")),
        date_inference = lambda w: conditional("--date-inference", config["refine"][w.build].get("date_inference")),
        timetree = lambda w: conditional("--timetree", config["refine"][w.build].get("timetree")),
        date_confidence = lambda w: conditional("--date-confidence", config["refine"][w.build].get("date_confidence")),
        clock_filter_iqd = lambda w: conditional("--clock-filter-iqd", config["refine"][w.build].get("clock_filter_iqd")),
        divergence_units = lambda w: conditional("--divergence-units", config["refine"][w.build].get("divergence_units")),
        strain_id = config.get("strain_id_field", "strain"),
    shell:
        r"""
        exec &> >(tee {log:q})

        augur refine \
            --tree {input.tree:q} \
            --alignment {input.alignment:q} \
            --metadata {input.metadata:q} \
            --metadata-id-columns {params.strain_id:q} \
            {params.timetree} \
            {params.coalescent} \
            {params.date_confidence} \
            {params.date_inference} \
            {params.clock_filter_iqd} \
            {params.divergence_units} \
            --output-tree {output.tree:q} \
            --output-node-data {output.node_data:q}
        """
