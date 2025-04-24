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


rule download:
    """Downloading sequences and metadata from data.nextstrain.org"""
    output:
        sequences = "data/sequences.fasta.zst",
        metadata = "data/metadata.tsv.zst"
    params:
        sequences_url = config["sequences_url"],
        metadata_url = config["metadata_url"],
    shell:
        """
        curl -fsSL --compressed {params.sequences_url:q} --output {output.sequences}
        curl -fsSL --compressed {params.metadata_url:q} --output {output.metadata}
        """

rule decompress:
    """Decompressing sequences and metadata"""
    input:
        sequences = "data/sequences.fasta.zst",
        metadata = "data/metadata.tsv.zst"
    output:
        sequences = "data/sequences.fasta",
        metadata = "data/metadata.tsv"
    shell:
        """
        zstd -d -c {input.sequences} > {output.sequences}
        zstd -d -c {input.metadata} > {output.metadata}
        """

rule merge_clade_membership:
    input:
        metadata="data/metadata.tsv",
        clade_membership="defaults/nextclade_reference_strains.tsv",
    output:
        merged_metadata="data/metadata_merged.tsv",
    benchmark:
        "benchmarks/merge_clade_membership.txt",
    params:
        metadata_id='accession',
        clade_membership_id='accession',
    shell:
        r"""
        augur merge \
        --metadata a={input.metadata:q} b={input.clade_membership:q} \
        --metadata-id-columns a={params.metadata_id:q} b={params.clade_membership_id:q} \
        --output-metadata {output.merged_metadata:q}
        """
