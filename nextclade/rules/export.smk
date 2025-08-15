"""
This part of the workflow collects the phylogenetic tree and annotations to
export a reference tree and create the Nextclade dataset.

REQUIRED INPUTS:

    augur export:
        metadata            = data/metadata.tsv
        tree                = results/tree.nwk
        branch_lengths      = results/branch_lengths.json
        nt_muts             = results/nt_muts.json
        aa_muts             = results/aa_muts.json
        clades              = results/clades.json

    Nextclade dataset files:
        reference           = ../shared/reference.fasta
        pathogen            = config/pathogen.json
        genome_annotation   = config/genome_annotation.gff3
        readme              = config/README.md
        changelog           = config/CHANGELOG.md
        example_sequences   = config/sequence.fasta

OUTPUTS:

    nextclade_dataset = datasets/${build_name}/*

    See Nextclade docs on expected naming conventions of dataset files
    https://docs.nextstrain.org/projects/nextclade/page/user/datasets.html

This part of the workflow usually includes the following steps:

    - augur export v2
    - cp Nextclade datasets files to new datasets directory

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
        exec &> >(tee {log:q})

        python3 ../phylogenetic/scripts/assign-colors.py \
            --color-schemes {input.color_schemes:q} \
            --ordering {input.color_orderings:q} \
            --metadata {input.metadata:q} \
            --output {output.colors:q}
        """

rule export:
    """Exporting data files for for auspice"""
    input:
        tree = "results/{build}/tree.nwk",
        metadata = "results/{build}/metadata.tsv",
        branch_lengths = "results/{build}/branch_lengths.json",
        traits = "results/{build}/traits.json",
        muts = "results/{build}/muts.json",
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
        exec &> >(tee {log:q})

        augur export v2 \
            --tree {input.tree:q} \
            --metadata {input.metadata:q} \
            --metadata-id-columns {params.strain_id:q} \
            --node-data {input.branch_lengths:q} {input.traits:q} {input.muts:q} \
            --lat-longs {input.lat_longs:q} \
            --colors {input.colors:q} \
            --auspice-config {input.auspice_config:q} \
            --description {input.description:q} \
            --include-root-sequence-inline \
            --output {output.auspice_json:q}
        """

rule assemble_dataset:
    input:
        reference="defaults/{build}/reference.fasta",
        tree="auspice/mumps_{build}.json",
        pathogen_json="defaults/{build}/pathogen.json",
        sequences="defaults/{build}/sequences.fasta",
        annotation="defaults/{build}/genome_annotation.gff3",
        readme="defaults/{build}/README.md",
        changelog="defaults/{build}/CHANGELOG.md",
    output:
        reference="datasets/{build}/reference.fasta",
        tree="datasets/{build}/tree.json",
        pathogen_json="datasets/{build}/pathogen.json",
        sequences="datasets/{build}/sequences.fasta",
        annotation="datasets/{build}/genome_annotation.gff3",
        readme="datasets/{build}/README.md",
        changelog="datasets/{build}/CHANGELOG.md",
    benchmark:
        "benchmarks/{build}/assemble_dataset.txt",
    shell:
        """
        cp {input.reference} {output.reference}
        cp {input.tree} {output.tree}
        cp {input.pathogen_json} {output.pathogen_json}
        cp {input.annotation} {output.annotation}
        cp {input.readme} {output.readme}
        cp {input.changelog} {output.changelog}
        cp {input.sequences} {output.sequences}
        """

rule test_dataset:
    input:
        tree="datasets/{build}/tree.json",
        pathogen_json="datasets/{build}/pathogen.json",
        sequences="defaults/{build}/sequences.fasta",
        annotation="datasets/{build}/genome_annotation.gff3",
        readme="datasets/{build}/README.md",
        changelog="datasets/{build}/CHANGELOG.md",
    output:
        outdir=directory("test_output/{build}"),
    log:
        "logs/{build}/test_dataset.txt",
    benchmark:
        "benchmarks/{build}/test_dataset.txt",
    params:
        dataset_dir="datasets/{build}",
    shell:
        """
        exec &> >(tee {log:q})

        nextclade run \
          --input-dataset {params.dataset_dir} \
          --output-all {output.outdir} \
          --silent \
          {input.sequences}
        """