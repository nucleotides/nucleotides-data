# Nucleotid.es input files

The data imported and used in [nucleotid.es][] is described by structured YAML
files. The aim these YAML files is to manage the large numbers of files and
Docker images used in nucleotid.es. Input files are designed to be
human-editable so that they may be updated with new entries as more
benchmarking files or Docker images are added. This document describes the
schema of the these files.

[nucleotid.es]: http://nucleotid.es

## File Overview

The data files are organised in the following directory structure:

<pre>
<b>data/</b>
├── benchmark_type.yml
├── image_instance.yml
├── <b>input_data/</b>
│   ├── data_file.yml
│   └── data_source.yml
└── <b>type/</b>
    ├── file.yml
    ├── image.yml
    ├── metric.yml
    ├── platform.yml
    ├── protocol.yml
    ├── run_mode.yml
    └── source.yml
</pre>

The `type` folder contains files for the all metadata 'types' used in the
benchmarks. An example of a metadata type is the `metrics.yml` file which
contains all the benchmarking metrics. An example value in this file is `lg50`
which is used to describe a genome assembly metric. Each metadata file follows
the same format - key/value pairs. An example of which is:

``` yaml
---
- name: Unique identifier within this file, uses only the characters a-z, 0-9 and '_'.
  description: A full text description of this metadata value.

# An example entry
- name: hiseq_2500
  description: The Illumina high-throughput short-read sequencer.
```

The `input_data` folder contains the files related to the input data files
(e.g. FASTQ) and the source of the data (e.g. *E.coli*). These files use the
metadata from the `types` folder to categorise the input data. The
`image_instance.yml` file lists all the [biobox][] Docker images used in the
benchmarking. The `type/image.yml` metadata is used to categorised the Docker
images. The `benchmark_type.yml` file combines the input data sets with the
Docker images. This describes which images are benchmarked with which data
sets.

[biobox]: http://bioboxes.org

## Input file descriptions

The following sections describe each of the files in more detail.

### File types

The file types are listed in `type/file.yml`. This contains all the possible
input files, and output files generated during benchmarking. Example entries
are:

``` yaml
- name: short_read_fastq
  desc: Short read sequences in FASTQ format
- name: contig_fasta
  desc: Reads assembled into larger contiguous sequences in FASTA format
```

### Image types

The types of Docker images used in benchmarking are listed in `type/image.yml`.
Each image type in the file corresponds to a type of [biobox][]. This file
should therefore not be changed unless new biobox types are created.

### Metric types

All metrics recorded from benchmarking are listed in `type/metric.yml`. These
metrics are the keys used to store the values from benchmarking. Example metric
types are:

``` yaml
---
- name: ng50
  desc: N50 normalised by reference genome length
- name: max_memory_usage
  desc: Maximum memory used when executing the Docker container
```

### Sequencing platform types

The different sequencing platforms used to generate the input sequence data in
nucleotid.es are described in `types/platform.yml`. This should be explicit
hardware models, rather than the name of the vendor company. Example entries
are:

``` yaml
- name: hiseq_2500
  description: An Illumina high-throughput short-read sequencer.
- name: pacbio_sequel
  description: Second generation Pacific Bioscience long-read sequencer.
```

### Library preparation protocol

Different sequencing DNA preparation protocols used on the same input DNA can
produce noticeable differences in the generated sequencing data. The file
`type/protocol.yml` lists the DNA preparation protocols. These are used to
describe the how input data in nucleotides was prepared. Examples entries are:

``` yaml
- name: blue_pippin
  description: Size selection protocol for high molecular weigh fragments
- name: nextera
  description: Single step fragmentation and tagging protocol for Illumina sequencing
```

### Sequencing run mode

Different sequencing run modes change the size and quality of data produced.
The file `type/run_mode.yml` describes the run mode used to produce the input
sequencing data used for benchmarking.

``` yaml
- name: 2x150_270
  description: Paired reads sequenced to 150bp with a target 270bp insert size.
- name: 2x250_400
  description: Paired reads sequenced to 250bp with a target 400bp insert size.
```

### Biological source type

All sequencing data input file originates from a single source such as a
microbe, fungus or environment. The file `type/source.yml` describes types of
input sources. Examples of this are:


``` yaml
- name: microbe
  description: Genomic DNA from a single isolated microbial colony
- name: metagenome
  description: Transcriptome data from a mixed community
```

## Input Data Source

All input data originates from a single biologial source such as a microbe,
fungus or environment. The file `input_data/source.yml` lists each biological
source of data along with any associated reference files. Two example entries
are:

``` yaml
---
- name: ecoli_k12
  description: A laboratory strain with a well-described genome
  source_type: microbe
  references:
  - file_type: reference_fasta
    sha256: eaa5305f8d0debbce934975c3ec6c14b
    url: s3://nucleotid-es/reference/0001/genome.fa
- name: kansas_farm_soil
  description: A soil sample from a kansas farm
  source_type: metagenome
  # This metagenome has no reference data
  references: []
```

The fields in this file are as follows:
  * name: The unique identifier within the file for this data source, uses only
    the characters a-z, 0-9 and '_'.
  * description: A full text description of what this data source is.
  * source_type: The identifier for the metadata value from the
    `type/source.yml` file. This is used categorise the source of the input
    data.
  * references: Zero or more reference files for this data. Each reference file
    is dictionary containing the files `file_type`, `sha256` and `url`. The
    sha256 is the digest of the file as produced by the shell command
    `sha256sum`. The `url` is the S3 location of the file. The `file_type`
    field corresponds to an entry in the `type/file.yml` metadata.

In the example above the ecoli_k12 entry has one reference file. The metagenome
entry has no reference files, as usually none exist for non-synthetic
metagenomes.

## Input Data File

The file `input_data/file.yml` contains the files used for benchmarking. Each
entry is a set of files from the same "batch". A batch is loosely defined and
might be read subsampling a single fastq file, or samples pooled in the same
sequencing run. Each entry includes metadata to cross reference the origin from
the `input_data/source.yml` file.

``` yaml
---
- name: jgi_isolate_microbe_2x150_1
  platform_type: hiseq_2500
  protocol_type: nextera
  run_mode_type: 2x150
  input_data_source: ecoli_k12
  description: >
    A plain text description of where these reads came from and how they were
    produced.
  replicates:
    - sha256: 87673a0358e2f248a4c44eccda8c46b4
      file_type: short_read_fastq
      url: s3://nucleotid-es/0001/0001/2000000/1/reads.fq.gz
    - sha256: c1f0fb4cad045641c1bd001c2f4dbe37
      url: s3://nucleotid-es/0001/0001/2000000/2/reads.fq.gz
      file_type: short_read_fastq
```

The fields in this file are as follows:
  * name: Unique identifier within this file, uses only the characters a-z, 0-9 and '_'.
  * description: A plain text description of the data.
  * platform_type / protocol_type / run_mode_type: The corresponding metadata
    for this data set. Corresponds to entries for the files found in the `type`
    folder.
  * input_data_source: The name of the originating source entry from the
    `input_data/source.yml` file.
  * replicates: The list of input data files for this data set. The name
    `replicates` is chosen to indicate this is how nucleotid.es views these
    input data files. These may be biological or technical replicates but not
    both as the replicates should be generated using the same method. This
    again is however loosely defined.

    Each replicate file is dictionary containing the files `file_type`,
    `sha256` and `url`. The sha256 is the digest of the file as produced by the
    shell command `sha256sum`. The `url` is the S3 location of the file. The
    `file_type` field corresponds to an entry in the `type/file.yml` metadata.

## Benchmarks

The `benchmark.yml` file describes the benchmarks performed within
nucleotid.es. Each entry corresponds to a type of benchmark and lists the types
of docker images used in producing results and then evaluating them.

```yaml
---
- name: short_read_isolate_assembly_with_reference
  description: >
    Text description of this benchmark
  product_image_type: short_read_assembler
  evaluation_image_type: reference_assembly_evaluator
  data_sets:
    - jgi_isolate_2x150
```

The fields in this file are:
  * name: Unique identifier within this file, uses only the characters a-z, 0-9 and '_'.
  * description: A plain text description of the benchmark.
  * product_image_type: The type of docker image to be benchmarked.
  * evaluation_image_type: The type of docker image to be used to evaluate the
    produced results.
  * data_sets: The list of IDs for the data sets to be used in the benchmarking.
