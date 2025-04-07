GEO = ["na","global"]

rule all:
    input:
        auspice_json = expand("auspice/mumps_{geo}.json", geo=GEO),

rule files:
    params:
        input_fasta = "data/mumps.fasta",
        dropped_strains = "config/dropped_strains_{geo}.txt",
        included_strains = "config/include_strains_{geo}.txt",
        reference = "config/mumps_reference.gb",
        colors = "config/colors.tsv",
        lat_longs = "config/mumps_lat_longs.tsv",
        auspice_config = "config/auspice_config_{geo}.json",
        auspice_config_v1 = "config/auspice_config_v1_{geo}.json",
        description = "config/description.md"

files = rules.files.params

rule align:
    """
    Aligning sequences to {input.reference}
      - filling gaps with N
    """
    input:
        sequences = "results/filtered_{geo}.fasta",
        reference = files.reference
    output:
        alignment = "results/aligned_{geo}.fasta"
    shell:
        """
        augur align \
            --sequences {input.sequences} \
            --reference-sequence {input.reference} \
            --output {output.alignment} \
            --fill-gaps
        """

rule tree:
    """Building tree"""
    input:
        alignment = "results/aligned_{geo}.fasta"
    output:
        tree = "results/tree-raw_{geo}.nwk"
    shell:
        """
        augur tree \
            --alignment {input.alignment} \
            --output {output.tree}
        """

def _get_clock_filter_by_wildcards(wildcards):
    if wildcards.geo == "na":
        clock_filter = "--clock-filter-iqd 4"
    else:
        clock_filter = ""
    return(clock_filter)

rule refine:
    """
    Refining tree
      - estimate timetree
      - use {params.coalescent} coalescent timescale
      - estimate {params.date_inference} node dates
      - filter tips more than {params.clock_filter_iqd} IQDs from clock expectation
    """
    input:
        tree = "results/tree-raw_{geo}.nwk",
        alignment = "results/aligned_{geo}.fasta",
        metadata = "results/metadata.tsv",
    output:
        tree = "results/tree_{geo}.nwk",
        node_data = "results/branch_lengths_{geo}.json"
    params:
        coalescent = "opt",
        date_inference = "marginal",
        clock_filter_iqd = _get_clock_filter_by_wildcards
    shell:
        """
        augur refine \
            --tree {input.tree} \
            --alignment {input.alignment} \
            --metadata {input.metadata} \
            --output-tree {output.tree} \
            --output-node-data {output.node_data} \
            --timetree \
            --coalescent {params.coalescent} \
            --date-confidence \
            --date-inference {params.date_inference} \
            {params.clock_filter_iqd}
        """

rule ancestral:
    """Reconstructing ancestral sequences and mutations"""
    input:
        tree = "results/tree_{geo}.nwk",
        alignment = "results/aligned_{geo}.fasta",
    output:
        node_data = "results/nt_muts_{geo}.json"
    params:
        inference = "joint"
    shell:
        """
        augur ancestral \
            --tree {input.tree} \
            --alignment {input.alignment} \
            --output-node-data {output.node_data} \
            --inference {params.inference}
        """

rule translate:
    """Translating amino acid sequences"""
    input:
        tree = "results/tree_{geo}.nwk",
        node_data = "results/nt_muts_{geo}.json",
        reference = files.reference
    output:
        node_data = "results/aa_muts_{geo}.json"
    shell:
        """
        augur translate \
            --tree {input.tree} \
            --ancestral-sequences {input.node_data} \
            --reference-sequence {input.reference} \
            --output-node-data {output.node_data} \
        """

def _get_traits_by_wildcards(wildcards):
    if wildcards.geo == "na":
        traits = ["country", "division"]
    else:
        traits = ["region"]
    return(traits)

rule traits:
    """Inferring ancestral traits for {params.columns!s}"""
    input:
        tree = "results/tree_{geo}.nwk",
        metadata = "results/metadata.tsv",
    output:
        node_data = "results/traits_{geo}.json",
    params:
        columns = _get_traits_by_wildcards
    shell:
        """
        augur traits \
            --tree {input.tree} \
            --metadata {input.metadata} \
            --output-node-data {output.node_data} \
            --columns {params.columns} \
            --confidence
        """

rule export:
    """Exporting data files for for auspice"""
    input:
        tree = "results/tree_{geo}.nwk",
        metadata = "results/metadata.tsv",
        branch_lengths = "results/branch_lengths_{geo}.json",
        traits = "results/traits_{geo}.json",
        nt_muts = "results/nt_muts_{geo}.json",
        aa_muts = "results/aa_muts_{geo}.json",
        colors = files.colors,
        lat_longs = files.lat_longs,
        auspice_config = files.auspice_config,
        description = files.description
    output:
        auspice_json = "auspice/mumps_{geo}.json"
    shell:
        """
        augur export v2 \
            --tree {input.tree} \
            --metadata {input.metadata} \
            --node-data {input.branch_lengths} {input.traits} {input.nt_muts} {input.aa_muts} \
            --colors {input.colors} \
            --lat-longs {input.lat_longs} \
            --auspice-config {input.auspice_config} \
            --description {input.description} \
            --include-root-sequence \
            --output {output.auspice_json}
        """

rule clean:
    """Removing directories: {params}"""
    params:
        "results ",
        "auspice"
    shell:
        "rm -rfv {params}"
