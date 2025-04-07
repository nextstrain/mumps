# Nextstrain repository for mumps virus

This repository contains three workflows for the analysis of mumps virus data:

- [`ingest/`] - Download data from GenBank, clean and curate it
- [`phylogenetic/`][] - Filter sequences, align, construct phylogeny,
  and export for visualization

Each workflow directory contains a `README.md` file with more
information. The results of running both workflows are publicly
visible at [nextstrain.org/mumps][].

## Installation

Follow the [standard installation instructions][] for Nextstrain's
suite of software tools.

## Quick start

Run the phylogenetic workflow by executing the following commands in
the repository checkout, after installing `nextstrain` per the above
instructions:

```bash
cd phylogenetic/
nextstrain build .
nextstrain view .
```

Further documentation is available at "[Running a pathogen workflow][]".

## Working on this repository

This repository is configured to use [pre-commit][] to help
automatically catch common coding errors and syntax issues with
changes before they are committed to the repo.

If you will be writing new code or otherwise working within this
repository, please do the following to get started:

1. install `pre-commit`, by running either `python -m pip install
   pre-commit` or `brew install pre-commit`, depending on your
   preferred package management solution
2. install the local git hooks by running `pre-commit install` from
   the root of the repository
3. when problems are detected, correct them in your local working tree
   before committing them.

Note that these pre-commit checks are also run in a GitHub Action when
changes are pushed to GitHub, so correcting issues locally will
prevent extra cycles of correction.

[`ingest/`]: ./ingest
[`phylogenetic/`]: ./phylogenetic
[nextstrain.org/mumps]: https://nextstrain.org/mumps
[Running a pathogen workflow]: https://docs.nextstrain.org/en/latest/tutorials/running-a-workflow.html
[pre-commit]: https://pre-commit.com
[standard installation instructions]: https://docs.nextstrain.org/en/latest/install.html
