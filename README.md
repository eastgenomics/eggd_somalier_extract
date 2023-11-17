# eggd_somalier_extract

## What does this app do?
This app runs Somalier to extract relevant sites to later (using eggd_somalier_relate) calculate relatedness and sex of samples.

Somalier extracts known sites that have a population allele frequency close to 0.5 - to maximize the probability that any 2 unrelated samples will differ. Somalier inspects sites which are in coding sequence, so they are applicable to WGS, WES and RNA-seq data. Somalier is slightly based off Peddy (https://github.com/brentp/peddy) - however Somalier can handle somatic and germline VCFs whereas Peddy can only handle germline VCFs.

This app is based on https://github.com/brentp/somalier

![Image of workflow]((somalier_v1.2.0).png)

## What are the inputs?
* This app only accepts VCFs as input. (Somalier can also handle bam/cram files, but this functionality is not currently implemented within the app.)
* Requires the reference genome and a snp sites vcf with the same build as the reference genome. (https://github.com/brentp/somalier/releases/).
* Docker image passed as input to allow easier updating.

## What are the outputs?
Output is a somalier file type with the sample name e.g Sample1.somalier - this file is binary.

## Where is this app applicable?
This app is only used to extract sites. The output file (.somalier) can be used to predict the relatedness and sex of sample. This app can be used in a single workflow as the app runs separately for each vcf file. The app can also be used if ancestry wants to be calculated.

## How does this app calculate relatedness and sex of sample?
To run sex check and relatedness - the app somalier_relate needs to be run. This will output a few tsv's and html of all samples sex, relatedness and ancestry.

### This app was made by East GLH