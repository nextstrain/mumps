"""
This part of the workflow handles running Nextclade on the curated metadata
and sequences.

REQUIRED INPUTS:

    metadata    = data/subset_metadata.tsv
    sequences   = results/sequences.fasta

OUTPUTS:

    metadata        = results/metadata.tsv
    nextclade       = results/nextclade.tsv
    alignment       = results/alignment.fasta
    translations    = results/translations.zip

See Nextclade docs for more details on usage, inputs, and outputs if you would
like to customize the rules:
https://docs.nextstrain.org/projects/nextclade/page/user/nextclade-cli.html
"""
DATASET_NAMES = config["nextclade"]["dataset_name"]

wildcard_constraints:
    DATASET_NAME = "|".join(DATASET_NAMES)


#rule get_nextclade_dataset:
#    """Download Nextclade dataset"""
#    output:
#        dataset=f"data/nextclade_data/{DATASET_NAME}.zip",
#    params:
#        dataset_name=DATASET_NAME
#    shell:
#        r"""
#        nextclade3 dataset get \
#            --name={params.dataset_name:q} \
#            --output-zip={output.dataset} \
#            --verbose
#        """


rule run_nextclade:
    input:
        dataset=lambda wildcards: directory(f"../nextclade_data/{wildcards.DATASET_NAME}"),
        sequences="results/sequences.fasta",
    output:
        nextclade="results/{DATASET_NAME}/nextclade.tsv",
        alignment="results/{DATASET_NAME}/alignment.fasta",
        translations="results/{DATASET_NAME}/translations.zip",
    log:
        "logs/{DATASET_NAME}/run_nextclade.txt",
    benchmark:
        "benchmarks/{DATASET_NAME}/run_nextclade.txt",
    params:
        translations=lambda w: "results/translations/{cds}.fasta",
    shell:
        r"""
        nextclade3 run \
            {input.sequences} \
            --input-dataset {input.dataset} \
            --output-tsv {output.nextclade} \
            --output-fasta {output.alignment} \
            --output-translations {params.translations} \
            --silent \
            2>&1 | tee {log:q}

        zip -rj {output.translations} results/translations
        """


rule nextclade_metadata:
    input:
        nextclade="results/{DATASET_NAME}/nextclade.tsv",
    output:
        nextclade_metadata=temp("results/{DATASET_NAME}/nextclade_metadata.tsv"),
    params:
        nextclade_id_field=config["nextclade"]["id_field"],
        nextclade_field_map=lambda wildcard: [f"{old}={new}" for old, new in config["nextclade"][wildcard.DATASET_NAME]["field_map"].items()],
        nextclade_fields=lambda wildcard: ",".join(config["nextclade"][wildcard.DATASET_NAME]["field_map"].values()),
    shell:
        r"""
        augur curate rename \
            --metadata {input.nextclade:q} \
            --id-column {params.nextclade_id_field:q} \
            --field-map {params.nextclade_field_map:q} \
            --output-metadata - \
        | csvtk cut -t --fields {params.nextclade_fields:q} \
        > {output.nextclade_metadata:q}
        """


rule join_metadata_and_nextclade:
    input:
        metadata="data/subset_metadata.tsv",
        sh_nextclade_metadata="results/sh/nextclade_metadata.tsv",
        genome_nextclade_metadata="results/genome/nextclade_metadata.tsv",
        genomesample_nextclade_metadata="results/genomesample/nextclade_metadata.tsv",
        genomesampleoutgroup_nextclade_metadata="results/genomesampleoutgroup/nextclade_metadata.tsv",
    output:
        metadata="results/metadata.tsv",
    params:
        metadata_id_field=config["curate"]["output_id_field"],
        nextclade_id_field=config["nextclade"]["id_field"],
    shell:
        r"""
        augur merge \
            --metadata \
                metadata={input.metadata:q} \
                sh_nextclade={input.sh_nextclade_metadata:q} \
                genome_nextclade={input.genome_nextclade_metadata:q} \
                genomesample_nextclade={input.genomesample_nextclade_metadata:q} \
                genomesampleoutgroup_nextclade={input.genomesampleoutgroup_nextclade_metadata:q} \
            --metadata-id-columns \
                metadata={params.metadata_id_field:q} \
                sh_nextclade={params.nextclade_id_field:q} \
                genome_nextclade={params.nextclade_id_field:q} \
                genomesample_nextclade={params.nextclade_id_field:q} \
                genomesampleoutgroup_nextclade={params.nextclade_id_field:q} \
            --output-metadata {output.metadata:q} \
            --no-source-columns
        """
