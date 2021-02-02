#!/bin/bash
# eggd_somalier_extract 0.0.1


# Exit at any point if there is any error and output each line as it is executed (for debugging)
set -exo pipefail

main() {

    echo "Value of input_file: '$input_file'"

    # The following line(s) use the dx command-line tool to download your file
    # inputs to the local file system using variable names for the filenames. To
    # recover the original filenames, you can use the output of "dx describe
    # "$variable" --name".


    dx download "$input_file" -o input_file
    org_filename=$(dx describe "$input_file" --name)
    mv input_file $org_filename

    echo "----------Load reference genome---------------"

    # Reference genome b37 (HS37D5.fa.gz)
    dx download project-Fkb6Gkj433GVVvj73J7x8KbV:file-F403K904F30y2vpVFqxB9kz7
    # Indexed reference genome
    dx download project-Fkb6Gkj433GVVvj73J7x8KbV:file-F3zxG0Q4fXX9YFjP1v5jK9jf
      
    service docker start

    # Load tabix
    docker load -i somalier_v0_2_12.tar.gz

    echo "---------- Extract sites into extracted/ ---------------"

    docker run -v /home/dnanexus:/data brentp/somalier:v0.2.12 gunzip /data/hs37d5.fa.gz

    docker run -v /home/dnanexus:/data brentp/somalier:v0.2.12 gunzip /data/hs37d5.fasta-index.tar.gz

    docker run -v /home/dnanexus:/data brentp/somalier:v0.2.12 /bin/bash -c "bgzip /data/*.annotated.vcf"

    docker run -v /home/dnanexus:/data brentp/somalier:v0.2.12 /bin/bash -c "tabix -p vcf /data/*.annotated.vcf.gz"

    docker run -v /home/dnanexus:/data brentp/somalier:v0.2.12 /bin/bash -c "somalier extract -d data/extracted/ --sites /data/sites.GRCh37.vcf -f /data/hs37d5.fa /data/*.annotated.vcf.gz"
    
    chmod 777 extracted/

    find extracted/ -type f -name "*" -print0 | xargs -0 -I {} mv {} .

    echo "--------------Renaming output files--------------" 
    # The filenames are extracted from the vcf files but we want to keep 
    # the filename from the original files

    filename="$(echo $org_filename | sed 's/_markdup_recalibrated_Haplotyper.refseq_nirvana_2010.annotated.vcf//')"
    echo $filename
    mv *.somalier ${filename}.somalier

    echo "--------------Uploading output files--------------"

    output=(`ls *.somalier`)
    echo $output

    out_file=$(dx upload /home/dnanexus/${output} --brief)

    dx-jobutil-add-output out_file "$out_file" --class=file
}

