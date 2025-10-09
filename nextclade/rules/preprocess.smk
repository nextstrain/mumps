"""
This part of the workflow preprocesses any data and files related to the
lineages/clades designations of the pathogen.

REQUIRED INPUTS:

    None

OUTPUTS:

    metadata    = data/metadata.tsv
    sequences   = data/sequences.fasta

    There will be many pathogen specific outputs from this part of the workflow
    due to the many ways lineages and/or clades are maintained and defined.

This part of the workflow usually includes steps to download and curate the required files.
"""

rule merge_clade_membership:
    input:
        metadata="results/metadata.tsv",
        clade_membership=resolve_config_path(config['clade_membership']['metadata']),
    output:
        merged_metadata=temp("data/{build}/metadata_merged_raw.tsv"),
    log:
        "logs/{build}/merge_clade_membership.txt",
    benchmark:
        "benchmarks/{build}/merge_clade_membership.txt",
    params:
        metadata_id=config.get("strain_id_field", "strain"),
        clade_membership_id=config.get("strain_id_field", "strain"),
    shell:
        r"""
        exec &> >(tee {log:q})

        augur merge \
        --metadata a={input.metadata:q} b={input.clade_membership:q} \
        --metadata-id-columns a={params.metadata_id:q} b={params.clade_membership_id:q} \
        --output-metadata {output.merged_metadata:q}
        """

rule fill_in_clade_membership:
    input:
        merged_metadata="data/{build}/metadata_merged_raw.tsv",
    output:
        merged_metadata="data/{build}/metadata_merged.tsv",
    log:
        "logs/{build}/fill_in_clade_membership.txt",
    benchmark:
        "benchmarks/{build}/fill_in_clade_membership.txt",
    params:
        clade_membership_column="clade_membership",
        genotype_column=config['clade_membership']['fallback']
    shell:
        r"""
        exec &> >(tee {log:q})

        python {workflow.basedir}/scripts/fill-clade-membership.py \
          --input-metadata {input.merged_metadata:q} \
          --output-metadata {output.merged_metadata:q} \
          --clade-membership-column {params.clade_membership_column:q} \
          --genotype-column {params.genotype_column:q}
        """

rule filter:
    """
    Filtering to
      - various criteria based on the auspice JSON target
      - excluding strains in {input.exclude}
      - including strains in {input.include}
    """
    input:
        sequences = "results/sequences.fasta",
        metadata = "data/{build}/metadata_merged.tsv",
        exclude = resolve_config_path(config['filter']['exclude']),
        include = resolve_config_path(config['filter']['include']),
    output:
        sequences = "results/{build}/filtered.fasta",
        metadata = "results/{build}/metadata.tsv",
    log:
        "logs/{build}/filtered.txt",
    benchmark:
        "benchmarks/{build}/filtered.txt",
    params:
        filter_params = lambda wildcard: config['filter'][wildcard.build],
        strain_id = config.get("strain_id_field", "strain"),
    shell:
        r"""
        exec &> >(tee {log:q})

        augur filter \
            --sequences {input.sequences:q} \
            --metadata {input.metadata:q} \
            --metadata-id-columns {params.strain_id:q} \
            --exclude {input.exclude:q} \
            --include {input.include:q} \
            --output-sequences {output.sequences:q} \
            --output-metadata {output.metadata:q} \
            {params.filter_params}
        """
