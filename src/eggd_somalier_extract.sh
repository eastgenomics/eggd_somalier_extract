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
    # Site for hg38 no chr vcf
    dx download project-FyXXbvQ4vQpqBK23B2vPjfVV:file-FyzvVzQ4vQpqbJ6X6g0GkB58

    ls
    
    # Need to unzip..
    echo "--------------Gunzip genome-----------------"

    gunzip hs37d5.fa.gz
    gunzip hs37d5.fasta-index.tar.gz

    ls -a

    # Compile tabix
    echo "--------------Compile tabix-----------------"
    cd /packages
    echo "--------------tar -jxvf tabix-0.2.6.tar.bz2-----------------"
    tar jxvf tabix-0.2.6.tar.bz2
    cd tabix-0.2.6
    make
    sudo cp bgzip tabix /usr/bin/  # need root access
    
    cd ~


    # Need to index sample vcf
    echo "--------------Index sample vcfs-----------------"
    bgzip input_file
    tabix -p vcf input_file.gz

    ls -a
    
    # Give permission rights to 
    echo "--------------Change permissions-----------------"
    sudo chmod 777 /usr/bin/somalier

    # Now run static binary in resources/usr/bin
    echo "--------------Run Somalier extract-----------------"
    somalier extract --sites sites.hg38.nochr.vcf -f hs37d5.fa input_file.gz
    ls -a

     
    echo "--------------Uploading output files--------------"

    output=(`ls *.somalier`)
    echo $output

    # The following line(s) use the utility dx-jobutil-add-output to format and
    # add output variables to your job's output as appropriate for the output
    # class.  Run "dx-jobutil-add-output -h" for more information on what it
    # does.

    mkdir -p /home/dnanexus/out/extracted/

    cp $output /home/dnanexus/out/extracted/${output}

    #dx-upload-all-outputs

    out_file=$(dx upload /home/dnanexus/out/extracted/${output} --brief)

    dx-jobutil-add-output out_file "$out_file" --class=file
}
