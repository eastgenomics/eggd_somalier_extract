# eggd_somalier_extract

## What does this app do?
This app runs Somalier (v0.2.12) to extract relevant sites to later (using eggd_somalier_relate) caluclare relatedness and sex of samples.

Somalier extracts known sites that have a population allele frequency close to 0.5 - to maximise the probablity that any 2 unrelated sample will differ. Somalier inspects sites which are in coding sequence so they are applicable to WGS, WES and RNA-seq data. Somalier is slighly based off Peddy (https://github.com/brentp/peddy) - however Somalier can handle somatic and germline VCFs whereas Peddy can only handle germline VCFs.

This app is based on https://github.com/brentp/somalier

![Image of workflow](https://github.com/eastgenomics/eggd_somalier_extract/blob/dev/somalier_extract_workflow.png)

## What are the inputs?
At the moment, VCFs can be inputted. Somalier can also handle bam/cram files. Defaults files are: b37 reference fasta file and sites.hg38.nochr.vcf which the latter is provided in the Somalier repo (https://github.com/brentp/somalier/releases/tag/v0.2.12).

## What are the outputs?
Output is a somalier file type with the sample name e.g Sample1.somalier - this file is binary.

## Where is this app applicable?
This app is only used to extract sites. The output file (.somalier) can be used to predict the relatedness and sex of sample. This app can be used in a single workflow as the app runs seperately for each vcf file.

## How does this app calculate relatedness and sex of sample?
To run sex check and relatedness - the app somalier_related needs to be run. This will output a tsv and html of all samples sex and relatedness.

### This app was made by EMEE GLH
