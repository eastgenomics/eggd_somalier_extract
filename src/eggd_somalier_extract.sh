#!/bin/bash
# eggd_somalier_extract 1.0.2


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
    dx download project-Fkb6Gkj433GVVvj73J7x8KbV:file-G1Gx2p8433Gg8Kf644jqxXJG -o somalier_v0_2_12.tar.gz
    dx ls


    # We need to store the filename as somalier extract will extract the 
    # sample id only from the vcf - so the somalier output will be sampleID.somalier.
    # We need to retain the other information in the full filename to later
    # pull out reported sex in the filname.

    echo "----------Extract sites into extracted/ using docker---------------"

    service docker start

    docker load -i somalier_v0_2_12.tar.gz

    docker run -v /home/dnanexus:/data brentp/somalier:v0.2.12 gunzip /data/reference_genome.gz

    docker run -v /home/dnanexus:/data brentp/somalier:v0.2.12 gunzip /data/reference_genome_index.gz

    docker run -v /home/dnanexus:/data brentp/somalier:v0.2.12 /bin/bash -c "tabix -p vcf /data/sample_vcf"

    docker run -v /home/dnanexus:/data brentp/somalier:v0.2.12 /bin/bash -c "somalier extract -d data/extracted/ --sites /data/snp_site_vcf -f /data/reference_genome /data/sample_vcf"
    
    chmod 777 extracted/

    # The somalier file is in extracted folder, move to the main folder

    mv extracted/*.somalier .

    echo "--------------Uploading output files--------------"

    output=(`ls *.somalier`)
    echo $output

    somalier_output=$(dx upload /home/dnanexus/${output} --brief)

    dx-jobutil-add-output somalier_output "$somalier_output" --class=file
}

