# Ingest

This workflow ingests public data from NCBI and outputs curated metadata and
sequences that can be used as input for the phylogenetic workflow.

If you have another data source or private data that needs to be formatted for
the phylogenetic workflow, then you can use a similar workflow to curate your
own data.

## Usage

### With `nextstrain run`

If you haven't set up the mumps pathogen, then set it up with:

```bash
nextstrain setup mumps
```

Otherwise, make sure you have the latest set up with:

```bash
nextstrain update mumps
```

Run the ingest workflow with:

```bash
nextstrain run mumps ingest <analysis-directory>
```

Your `<analysis-directory>` will contain the workflow's intermediate files
and two final outputs:

- `results/metadata.tsv`
- `results/sequences.fasta`

#### Dumping the full raw metadata from NCBI Datasets

The workflow has a target for dumping the full raw metadata from NCBI Datasets.

```bash
nextstrain run mumps ingest <analysis-directory> dump_ncbi_dataset_report
```

This will produce the file `<analysis-directory>/data/ncbi_dataset_report_raw.tsv`,
which you can inspect to determine what fields and data to use if you want to
configure the workflow.

### With `nextstrain build`

If you don't have a local copy of the mumps repository, use Git to download it

```bash
git clone https://github.com/nextstrain/mumps.git
```

Otherwise, update your local copy of the workflow with:

```bash
cd mumps
git pull --ff-only origin main
```

Run the ingest workflow with

```bash
cd ingest
nextstrain build .
```

The `ingest` directory will contain the workflow's intermediate files
and two final outputs:

- `results/metadata.tsv`
- `results/sequences.fasta`

#### Dumping the full raw metadata from NCBI Datasets

The workflow has a target for dumping the full raw metadata from NCBI Datasets.

```bash
cd ingest
nextstrain build . dump_ncbi_dataset_report
```

This will produce the file `ingest/data/ncbi_dataset_report_raw.tsv`,
which you can inspect to determine what fields and data to use if you want to
configure the workflow.

## Defaults

The defaults directory contains all of the default configurations for the ingest workflow.

[defaults/config.yaml](defaults/config.yaml) contains all of the default configuration parameters
used for the ingest workflow. Use Snakemake's `--configfile`/`--config`
options to override these default values.

## Snakefile and rules

The rules directory contains separate Snakefiles (`*.smk`) as modules of the core ingest workflow.
The modules of the workflow are in separate files to keep the main ingest [Snakefile](Snakefile) succinct and organized.

The `workdir` is hardcoded to be the ingest directory so all filepaths for
inputs/outputs should be relative to the ingest directory.

Modules are all [included](https://snakemake.readthedocs.io/en/stable/snakefiles/modularization.html#includes)
in the main Snakefile in the order that they are expected to run.

## Build configs

The build-configs directory contains custom configs and rules that override and/or
extend the default workflow.

- [nextstrain-automation](build-configs/nextstrain-automation/) - automated internal Nextstrain builds.

### Nextstrain automated workflow

The Nextstrain automated workflow uploads results to AWS S3 with

```bash
nextstrain build \
    --env AWS_ACCESS_KEY_ID \
    --env AWS_SECRET_ACCESS_KEY \
    . \
        upload_all \
        --configfile build-configs/nextstrain-automation/config.yaml
```

## Input data

### GenBank data

GenBank sequences and metadata are fetched via [NCBI datasets](https://www.ncbi.nlm.nih.gov/datasets/docs/v2/download-and-install/).