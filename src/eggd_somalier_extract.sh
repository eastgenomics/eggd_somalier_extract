#!/bin/bash
# eggd_somalier_extract 0.0.1


# Exit at any point if there is any error and output each line as it is executed (for debugging)
set -e -x -o pipefail

main() {

    echo "Value of input_file: '$input_file'"

    # The following line(s) use the dx command-line tool to download your file
    # inputs to the local file system using variable names for the filenames. To
    # recover the original filenames, you can use the output of "dx describe
    # "$variable" --name".


    dx download "$input_file" -o input_file

    echo "----------Load reference genome---------------"

    # Reference genome b37 (HS37D5.fa.gz)
    dx download project-Fkb6Gkj433GVVvj73J7x8KbV:file-F403K904F30y2vpVFqxB9kz7
    # Indexed reference genome
    dx download project-Fkb6Gkj433GVVvj73J7x8KbV:file-F3zxG0Q4fXX9YFjP1v5jK9jf
    # Site for GRCh37 no chr vcf
    # dx download project-FyXXbvQ4vQpqBK23B2vPjfVV:file-Fz0jV9j4vQpqP7pY7J94y4qx

    ls -a
    
    echo "---------- Extract (docker 1)---------------"
    
    service docker start

    # Compile tabix
    docker load -i somalier_v0_2_12.tar.gz

    echo "---------- Extract (docker 2)---------------"

    docker run -v /home/dnanexus:/data brentp/somalier:v0.2.12 gunzip /data/hs37d5.fa.gz

    docker run -v /home/dnanexus:/data brentp/somalier:v0.2.12 gunzip /data/hs37d5.fasta-index.tar.gz

    docker run -v /home/dnanexus:/data brentp/somalier:v0.2.12 bgzip /data/input_file

    docker run -v /home/dnanexus:/data brentp/somalier:v0.2.12 tabix -p vcf /data/input_file.gz

    docker run -v /home/dnanexus:/data brentp/somalier:v0.2.12 somalier extract -d data/extracted/ --sites /data/sites.GRCh37.vcf -f /data/hs37d5.fa /data/input_file.gz

    ls -a

     
    echo "--------------Uploading output files--------------"
    chmod 777 extracted/

    find extracted/ -type f -name "*" -print0 | xargs -0 -I {} mv {} .

    output=(`ls *.somalier`)
    echo $output

    out_file=$(dx upload /home/dnanexus/${output} --brief)

    dx-jobutil-add-output out_file "$out_file" --class=file
}

