# Phylogenetic workflow

This workflow uses metadata and sequences to produce one or multiple
[Nextstrain datasets][] that can be visualized in Auspice.

## Usage

If you're unfamiliar with Nextstrain builds, you may want to follow our
[Running a Pathogen Workflow guide][] first and then come back here.

### With `nextstrain run`

If you haven't set up the mumps pathogen, then set it up with:

```bash
nextstrain setup mumps
```

Otherwise, make sure you have the latest set up with:

```bash
nextstrain update mumps
```

Run the phylogenetic workflow with:

```bash
nextstrain run mumps phylogenetic <analysis-directory>
```

Your `<analysis-directory>` will contain the workflow's intermediate files
and the final output `auspice/mumps_genome.json` and `auspice/mumps_sh.json`.

You can view the result with

```bash
nextstrain view <analysis-directory>
```

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

Run the phylogenetic workflow workflow with

```bash
cd phylogenetic
nextstrain build .
```

The `phylogenetic` directory will contain the workflow's intermediate files
and the final output `auspice/mumps_genome.json` and `auspice/mumps_sh.json` .

Once you've run the build, you can view the results with:

```bash
nextstrain view .
```

## Data Requirements

The core phylogenetic workflow will use metadata values as-is, so
please do any desired data formatting and curations as part of the
[ingest][] workflow.

1. The metadata must include an ID column that can be used as as exact
   match for the sequence ID present in the FASTA headers.
2. The `date` column in the metadata must be in ISO 8601 date format
   (i.e. YYYY-MM-DD).
3. Ambiguous dates should be masked with `XX` (e.g. 2023-01-XX).

## Config

[defaults/config.yaml][] contains all of the default configuration
parameters used for the phylogenetic workflow. Use Snakemake's
`--configfile`/`--config` options to override these default values.

## Snakefile and rules

The rules directory contains separate Snakefiles (`*.smk`) as modules
of the core phylogenetic workflow. The modules of the workflow are in
separate files to keep the main ingest [Snakefile][] succinct and
organized. Modules are all [included][] in the main Snakefile in the
order that they are expected to run.

[defaults/config.yaml]: ./config/defaults.yaml
[included]: https://snakemake.readthedocs.io/en/stable/snakefiles/modularization.html#includes
[ingest]: ../ingest/
[Nextstrain datasets]: https://docs.nextstrain.org/en/latest/reference/glossary.html#term-dataset
[Snakefile]: ./Snakefile
