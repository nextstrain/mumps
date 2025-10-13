# CHANGELOG

We use this CHANGELOG to document breaking changes, new features, bug fixes,
and config value changes that may affect both the usage of the workflows and
the outputs of the workflows.

## 2025

* 13 October 2025: phylogenetic and nextclade - Update to color handling ([#48][])
  * phylogenetic colors - generate one colors.tsv to be used with all builds for consistency
  * nextclade colors - generate separate colors.tsv files per dataset since clade_membership may be different

* 13 October 2025: phylogenetic and nextclade - Major update to the definition of inputs. ([#48][])

The configuration has been updated from top level keys:

```yaml
sequences_url: "https://data.nextstrain.org/files/workflows/mumps/sequences.fasta.zst"
metadata_url: "https://data.nextstrain.org/files/workflows/mumps/metadata.tsv.zst"
```

to named dictionary key of multiple inputs:

```yaml
inputs:
  - name: ncbi
    sequences: "https://data.nextstrain.org/files/workflows/mumps/sequences.fasta.zst"
    metadata: "https://data.nextstrain.org/files/workflows/mumps/metadata.tsv.zst"
```

[#48]: https://github.com/nextstrain/mumps/pull/48
