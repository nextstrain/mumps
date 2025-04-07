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
