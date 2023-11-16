#!/bin/bash
# eggd_somalier_extract


# Exit at any point if there is any error and output each line as it is executed (for debugging)
set -exo pipefail

main() {

    echo "sample_vcf: '$sample_vcf_name'"
    echo "snp_site_vcf: '$snp_site_vcf_name'"
    echo "reference_fasta_tar: '$reference_fasta_tar_name'"
    echo "somalier_docker: '$somalier_docker_name'"

    echo "----------Load input data---------------"

    dx-download-all-inputs --parallel
    find ~/in -type f -name "*" -print0 | xargs -0 -I {} mv {} ~/

    # We need to store the filename as somalier extract will extract the
    # sample id only from the vcf - so the somalier output will be sampleID.somalier.
    # We need to retain the other information in the full filename to later
    # pull out reported sex in the filename.

    echo "----------Extract sites into extracted/ using docker---------------"

    service docker start

    # Load docker image
    docker load -i "${somalier_docker_name}"

    # Get image id from docker image loaded
    SOM_IMAGE_ID=$(sudo docker images --format="{{.Repository}} {{.ID}}" | grep "^brentp" | cut -d' ' -f2)

    docker run -v /home/dnanexus:/data "${SOM_IMAGE_ID}" tar -xzvf /data/"${reference_fasta_tar_name}" -C /data/
    REF_GEN=$(find /home/dnanexus/ -type f \( -iname \*.fa -o -iname \*.fasta -o -iname \*.fas \) -printf "%f")

    # If sample is not bgzip, then bgzip it
    # use command file which describes what type of file you have

    if [[ "$sample_vcf_name" == *.vcf ]]; then
        docker run -v /home/dnanexus:/data ${SOM_IMAGE_ID} bgzip /data/"${sample_vcf_name}"
        input_vcf="${sample_vcf_name}.gz"
    else
        echo 'Already compressed'
        input_vcf="${sample_vcf_name}"
    fi

    docker run -v /home/dnanexus:/data ${SOM_IMAGE_ID} tabix -p vcf /data/${input_vcf}

    docker run -v /home/dnanexus:/data ${SOM_IMAGE_ID} \
    somalier extract -d data/extracted/ --sites /data/${snp_site_vcf_name} -f /data/"${REF_GEN}" /data/${input_vcf}

    chmod 777 extracted/

    # The somalier file is in extracted folder, move to the main folder

    mv extracted/*.somalier .

    echo "--------------Uploading output files--------------"

    output=(`ls *.somalier`)
    echo $output

    somalier_output=$(dx upload /home/dnanexus/${output} --brief)

    dx-jobutil-add-output somalier_output "$somalier_output" --class=file
}

