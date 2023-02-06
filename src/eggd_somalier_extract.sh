#!/bin/bash
# eggd_somalier_extract 1.0.3


# Exit at any point if there is any error and output each line as it is executed (for debugging)
set -exo pipefail

main() {

    echo "sample_vcf: '$sample_vcf'"
    echo "snp_site_vcf: '$snp_site_vcf'"
    echo "reference_genome: '$reference_genome'"
    echo "reference_genome_index: '$reference_genome_index'"

    echo "----------Load input data---------------"

    dx download "$sample_vcf" -o sample_vcf
    dx download "$snp_site_vcf" -o snp_site_vcf
    dx download "$reference_genome" -o reference_genome.gz
    dx download "$reference_genome_index" -o reference_genome_index.gz
    dx download "$somalier_docker" -o somalier.tar.gz
    dx ls


    # We need to store the filename as somalier extract will extract the
    # sample id only from the vcf - so the somalier output will be sampleID.somalier.
    # We need to retain the other information in the full filename to later
    # pull out reported sex in the filename.

    echo "----------Extract sites into extracted/ using docker---------------"

    service docker start

    # Load docker image
    docker load -i somalier.tar.gz

    # Get image id from docker image loaded
    VEP_IMAGE_ID=$(sudo docker images --format="{{.Repository}} {{.ID}}" | grep "^brentp" | cut -d' ' -f2)


    docker run -v /home/dnanexus:/data ${VEP_IMAGE_ID} gunzip /data/reference_genome.gz

    docker run -v /home/dnanexus:/data ${VEP_IMAGE_ID} gunzip /data/reference_genome_index.gz

    # If sample is not bgzip, then bgzip it
    # use command file which describes what type of file you have

    docker run -v /home/dnanexus:/data ${VEP_IMAGE_ID} /bin/bash -c " \
    if [[ $(file -b --mime-type sample_vcf) == 'application/gzip' ]]; \
    then echo 'already compressed' ; else echo 'not compressed' ; \
    bgzip /data/sample_vcf; mv /data/sample_vcf.gz /data/sample_vcf; fi"

    docker run -v /home/dnanexus:/data ${VEP_IMAGE_ID} /bin/bash -c " \
    tabix -p vcf /data/sample_vcf"

    docker run -v /home/dnanexus:/data ${VEP_IMAGE_ID} /bin/bash -c " \
    somalier extract -d data/extracted/ --sites /data/snp_site_vcf \
    -f /data/reference_genome /data/sample_vcf"

    chmod 777 extracted/

    # The somalier file is in extracted folder, move to the main folder

    mv extracted/*.somalier .

    echo "--------------Uploading output files--------------"

    output=(`ls *.somalier`)
    echo $output

    somalier_output=$(dx upload /home/dnanexus/${output} --brief)

    dx-jobutil-add-output somalier_output "$somalier_output" --class=file
}

