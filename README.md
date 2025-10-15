# Mumps- Washington Focused Build

## Build Overview
- **Build Name**: Mumps- Washington Focused Build
- **Pathogen/Strain**: Mumps/MuV
- **Scope**: Genotype G whole genomes (2006–present).
- **Purpose**: This repository contains the Nextstrain build for Washington State genomic surveillance of mumps. It is specifically designed to retain all available mumps sequences from Washington State, while also incorporating representative samples from the United States, North America, and a reduced set of global background sequences. The build focuses on whole-genome sequences of genotype G collected since 2006, which is the lineage responsible for nearly all recent mumps outbreaks in the United States.
- **Considerations**: The Washington-focused mumps build reuses much of the Nextstrain global mumps workflow
, with local modifications to the configuration and subsampling strategies. This README explains how the Washington-specific build relates to and depends on the global mumps build, and how it can be adapted.
- **Nextstrain Build/s Location/s**:
  - https://github.com/NW-PaGe/mumps
  - https://github.com/nextstrain/mumps

## Table of Contents
- [Pathogen Epidemiology](#pathogen-epidemiology)
- [Scientific Decisions](#scientific-decisions)
- [Getting Started](#getting-started)
  - [Data Sources & Inputs](#data-sources--inputs)
  - [Setup & Dependencies](#setup--dependencies)
    - [Installation](#installation)
    - [Clone the repository](#clone-the-repository)
- [Run the Build](#run-the-build-with-test-data)
  - [Expected Outputs](#expected-outputs)
  - [Visualizing Results](#visualize-results)
- [Customization for Local Adaptation](#customization-for-local-adaptation)
- [Contributing](#contributing)
- [License](#license)
- [Acknowledgements](#acknowledgements)


## Pathogen Epidemiology
- Overview:
  - Mumps virus (MuV), a negative-sense single-stranded RNA virus in the family Paramyxoviridae.
  - Twelve recognized genotypes (A–N, excluding E and M). In the U.S., genotype G has been dominant since ~2006.
  - Mode of transmision include respiratory droplets, saliva, or direct contact with fomites. Highly transmissible in close-contact environments (schools, dormitories).

- Geographic Distribution and Seasonality
  - Globally distributed, with recurrent outbreaks in Europe and North America despite high vaccination coverage.
  - Washington has experienced recurrent outbreaks, often linked to close-contact settings.
  - Transmission may occur year-round, but outbreaks often cluster in late winter and spring.

- Public Health Importance
  - Outbreaks occur in vaccinated populations due to waning immunity.
  - Important for outbreak response, vaccination strategies, and cluster detection.

- Genomic Relevance
  - Enables tracking of introductions vs. sustained transmission.
  - Identifies linkages between Washington and external cases.
  - Supports outbreak investigations, especially in congregate settings.

- Additional Resources
  - https://www.cdc.gov/mumps/about/index.html 
  - Link Pathogen Genomic Profile if we have one created

## Scientific Decisions
Nextstrain builds are designed for specific purposes and not all types of builds for a particular pathogen will answer the same questions. The following are critical decisions that were made during the development of this build that should be kept in mind when analyzing the data and using this build.

- **Nomenclature**: CDC genotype nomenclature.
- **Subsampling**: For this build, subsampling was designed to prioritize Washington State sequences while maintaining appropriate contextual diversity. All available Washington genotype G sequences are retained without limitation to ensure complete coverage of local transmission dynamics. To provide regional perspective, U.S. sequences outside of Washington are subsampled evenly by division, while additional contextual sequences are drawn from Canada and Mexico. A reduced number of global sequences are included to preserve phylogenetic background without overwhelming the Washington-specific signals.
- **Root selection**: In order to be Nextclade compatable, the reference sequence for the North America and Global builds from the original Nextstrain Mumps repo was used as the forced root. GenBank KM597072 https://www.ncbi.nlm.nih.gov/nuccore/KM597072
- **Reference selection**: The alignment and mutation calling are performed against a MuV-G reference genome KM597072, which provides a consistent baseline for variant calling and comparative analysis.
- **Inclusion/Exclusion**: In terms of inclusion and exclusion, the build accepts only sequences from 2006 onward to reflect the era of genotype G predominance. Sequences from other genotypes, those with incomplete genomes, and those with insufficient or poor-quality metadata are excluded to ensure reliability.
- **Other adjustments**: Additional adjustments include applying maximum thresholds on the number of contextual sequences retained from outside Washington while leaving Washington itself unrestricted, guaranteeing that no local data are lost. Low-quality or hypervariable regions of the genome are masked during analysis to reduce noise and improve phylogenetic accuracy.

## Getting Started
- **Washington Prioritization**: The build exposes geography at the U.S. state level via the Division field, allowing rapid side-by-side comparisons of Washington sequences against other states without leaving the tree. Coloring or filtering by Division makes it straightforward to spot cross-border introductions and to confirm whether an apparent Washington clade is actually seeded by multiple states.
- **MuV genotype & Nextclade Calls**: In Auspice, the dataset ships with genotype-aware views that surface three complementary annotations: the source MuV genotype (GenBank) and the Nextclade genotype calls for both the SH gene and the whole genome. Switching among these in the Color by menu lets analysts verify concordance (or flag discrepancies) between database metadata and algorithmic assignments, which is especially helpful when triaging suspected clusters or quality-controlling new submissions.

### Data Sources & Inputs
- How Samples are Ingested from NCBI: `mumps/ingest/rules/fetch_from_ncbi.smk` 
- How Samples are Prepared for Sequencing: `mumps/phylogenetic/rules/prepare_sequences.smk`

- This build relies on publicly available data sourced from data.nextstrain.org which originates from NCBI. This data is generously shared by labs around the world and deposited in NCBI genbank by the authors. Please contact these labs first if you plan to publish using their data.

- **Sequence Data**: All sequence data originate from [NCBI](https://www.ncbi.nlm.nih.gov/).
- **Metadata**: All metadata originate from [NCBI](https://www.ncbi.nlm.nih.gov/).
- **Expected Inputs**:
    - `mumps/phylogenetic/data/sequences.fasta` (containing viral genome sequences)
    - `mumps/phylogenetic/data/metadata.tsv` (with relevant sample information)

### Setup & Dependencies
#### Installation
Ensure that you have [Nextstrain](https://docs.nextstrain.org/en/latest/install.html) installed.

To check that Nextstrain is installed:
```
nextstrain check-setup
```

#### Clone the repository:

```
git clone https://github.com/NW-PaGe/mumps.git
cd mumps/phylogenetic
```

## Run the Build
Ensure you are located in the build folder `phylogenetic` before running the build command:
```
nextstrain build . --configfile washington/config.yaml
```

When you run the build, Snakemake serves as the workflow manager that orchestrates the genomic analyses in an automated fashion. The Snakefile defines the series of steps needed to process raw sequence and metadata inputs, ensuring that each stage is carried out in the correct order. Within this framework, Augur handles the phylogenetic analyses, Auspice generates the interactive visualizations, and Snakemake coordinates their execution by tracking file dependencies.
Alternative configuration files allow you to adjust the workflow for specific goals. For example, using `--configfile washington/config.yaml` tailors the subsampling scheme so that the build prioritizes sequences from Washington state first, followed by North America, and then global samples, with the proportions controlled by the settings in the configuration file.

Before running the `ingest` workflow, the build will automatically pull data from the Nextstrain mumps data repository, which is periodically refreshed. However, if you prefer to retrieve the most current data directly from NCBI, you should run the ingest workflow first by executing `nextstrain build .` from the `ingest` directory. The Washington-focused build will check the `ingest/results` directory for locally generated data and use it if available; otherwise, it defaults to the Nextstrain repository. To guarantee that your build always incorporates the latest sequences from NCBI, you can run the following commands from the main `mumps/` directory:
```
nextstrain build ingest --forceall &&
nextstrain build phylogenetic --configfile washington/config.yaml
```
This ensures that the ingest step refreshes the dataset before the Washington-specific build is executed.

### Run the Build with Test Data (Optional)
An alternative configuration file is available for running the phylogenetic workflow on a smaller example dataset. By using `--configfile build-configs/ci/config.yaml`, the workflow is adjusted so that the dataset in `phylogenetic/example_data` is copied into `phylogenetic/data`, thereby skipping the default steps of downloading and decompressing the full Nextstrain dataset.

### Expected Outputs
The file structure of the repository is as follows with `*`" folders denoting folders that are the build's expected outputs.

```
.
├── README.md
├── Snakefile
├── auspice*
└── benchmarks*
├── build-configs
├── data
├── defaults
├── example_data
└── logs*
├── results*
└── rules
└── scripts
├── washington
```
More details on the file structure of this build can be found [here](https://github.com/DOH-DAH0303/mumps/wiki)

After successfully running the build there will be two output folders containing the build results.
- `auspice/` folder contains: `mumps_washington.json`. This is the final result viewable by auspice.
- `results/washington` folder contains: The raw tree, amino acid mutations, nucleotide mutations etc. 


### Visualize Results
- Open [auspice.us](auspice.us) in a web browser, and drop `phylogenetic/auspice/mumps_washington.json` in as input. 
- For guidance on phylogenetic inference, see [The Applied Genomic Epidemiology Handbook](https://www.czbiohub.org/ebook/applied-genomic-epidemiology-handbook/welcome-to-the-applied-genomic-epidemiology-handbook/).


## Customization for Local Adaptation
This build can be customized for use by other states. This is configurable by editing the following files:

  - `mumps/phylogenetic/washington/auspice_config.json` lines 2, 4, and 12. 
    - **line 2:** "title": "Genomic Epidemiology of Mumps Virus - [Insert State] State Focused Build",
    - **line 4:** {"name": "[Insert name]", "url": "[Insert url]"}
    - **line 12:** "build_url": "[Insert url]",
      
  - `mumps/phylogenetic/washington/config.yaml` lines 5, 9, 10, 20, and 35. 
    - **line 5:**   - [Insert your state's name]
    - **line 9:**   auspice_config: [Insert your state's folder name]/auspice_config.json
    - **line 10:**  description: [Insert your state's folder name]/description.md
    - **line 20:**  [change to match line 5]: [Insert your state's folder name]/subsampling.yaml
    - **line 35:**  [Change to match line 5 and 20]: >-
      
  - `mumps/phylogenetic/washington/description.md`
    - Change the description file to meet your own builds needs.
   
  - `mumps/phylogenetic/washington/subsampling.yaml` lines 4, 5, and 14. 
    - **line 4:**   [Insert your state]_all:
    - **line 5:**   query: "country == 'USA' & division == '[Insert your state]'"
    - **line 14:**  query: --query "(country == 'USA') & (division != '[Insert your state]') & (MuV_genotype == 'G')"

## Contributing
For any questions please submit them to our [Discussions](https://github.com/orgs/NW-PaGe/discussions) page. Software issues and requests can be logged as a Git [Issue](insert link here).

## License
This project is licensed under a modified GPL-3.0 License.
You may use, modify, and distribute this work, but commercial use is strictly prohibited without prior written permission.

## Acknowledgements

Workflow based on Nextstrain mumps
Adapted structure from NW-PaGe mpox
Data contributions from GISAID, GenBank, CDC, and WA DOH laboratories.
