"""
This part of the workflow collects the phylogenetic tree and annotations to
export a Nextstrain dataset.

REQUIRED INPUTS:

    metadata        = data/metadata.tsv
    tree            = results/tree.nwk
    branch_lengths  = results/branch_lengths.json
    node_data       = results/*.json

OUTPUTS:

    auspice_json = auspice/${build_name}.json

    There are optional sidecar JSON files that can be exported as part of the dataset.
    See Nextstrain's data format docs for more details on sidecar files:
    https://docs.nextstrain.org/page/reference/data-formats.html

This part of the workflow usually includes the following steps:

    - augur export v2
    - augur frequencies

See Augur's usage docs for these commands for more details.
"""

rule colors:
    """Generate color pallete for color by metadata in auspice"""
    input:
        color_schemes = config['colors']['color_schemes'],
        color_orderings = config['colors']['color_orderings'],
        metadata = "results/{build}/metadata.tsv",
    output:
        colors = "results/{build}/colors.tsv"
    log:
        "logs/{build}/colors.txt",
    benchmark:
        "benchmarks/{build}/colors.txt"
    shell:
        r"""
        python3 scripts/assign-colors.py \
            --color-schemes {input.color_schemes:q} \
            --ordering {input.color_orderings:q} \
            --metadata {input.metadata:q} \
            --output {output.colors:q} \
            2>&1 | tee {log}
        """

rule export:
    """Exporting data files for for auspice"""
    input:
        tree = "results/{build}/tree.nwk",
        metadata = "data/metadata.tsv",
        branch_lengths = "results/{build}/branch_lengths.json",
        traits = "results/{build}/traits.json",
        nt_muts = "results/{build}/nt_muts.json",
        aa_muts = "results/{build}/aa_muts.json",
        lat_longs = config['export']['lat_longs'],
        colors = "results/{build}/colors.tsv",
        auspice_config = config['export']['auspice_config'],
        description = config['export']['description'],
    output:
        auspice_json = "auspice/mumps_{build}.json",
    log:
        "logs/{build}/export.txt",
    benchmark:
        "benchmarks/{build}/export.txt",
    params:
        strain_id = config.get("strain_id_field", "strain"),
    shell:
        r"""
        augur export v2 \
            --tree {input.tree:q} \
            --metadata {input.metadata:q} \
            --metadata-id-columns {params.strain_id:q} \
            --node-data {input.branch_lengths:q} {input.traits:q} {input.nt_muts:q} {input.aa_muts:q} \
            --lat-longs {input.lat_longs:q} \
            --colors {input.colors:q} \
            --auspice-config {input.auspice_config:q} \
            --description {input.description:q} \
            --include-root-sequence \
            --output {output.auspice_json:q} | tee {log:q}
        """