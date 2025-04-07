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
