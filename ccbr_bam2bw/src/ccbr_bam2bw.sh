#!/bin/bash
# ccbr_bam2bw 0.0.1
# Generated by dx-app-wizard.
#
# Basic execution pattern: Your app will run on a single machine from
# beginning to end.
#
# Your job's input variables (if any) will be loaded as environment
# variables before this script runs.  Any array inputs will be loaded
# as bash arrays.
#
# Any code outside of main() (or any entry point you may add) is
# ALWAYS executed, followed by running the entry point itself.
#
# See https://wiki.dnanexus.com/Developer-Portal for tutorials on how
# to modify this file.

main() {

    echo "Value of BwaIndex: '$BwaIndex'"
    echo "Value of TreatmentBam: '$TreatmentBam'"
    echo "Value of TreatmentPPQT: '$TreatmentPPQT'"
	echo "Value of InputBam: '$InputBam'"

    # The following line(s) use the dx command-line tool to download your file
    # inputs to the local file system using variable names for the filenames. To
    # recover the original filenames, you can use the output of "dx describe
    # "$variable" --name".
mkdir -p /data
cd /data

reftargz=$(dx describe "$BwaIndex" --name)
genome=${reftargz%%.*}

if [ "$genome" == "mm10" ]; then
genomesize="2652783500"
elif [ "$genome" == "hg19" ]; then
genomesize="2864785220"
elif [ "$genome" == "hg38" ]; then
genomesize="2913022398"
elif [ "$genome" == "mm9" ]; then
genomesize="2620345972"
fi

treatmentbam=$(dx describe "$TreatmentBam" --name)
dx download "$TreatmentBam" -o $treatmentbam
treatmentppqt=$(dx describe "$TreatmentPPQT" --name)
dx download "$TreatmentPPQT" -o $treatmentppqt
inputbam=$(dx describe "$InputBam" --name)
dx download "$InputBam" -o $inputbam

treatmentbw=`echo $treatmentbam|sed "s/.bam/.bw/g"`
inputbw=`echo $inputbam|sed "s/.bam/.bw/g"`
treatmentextsize=`cat $treatmentppqt|awk -F"\t" '{print $3}'|awk -F"," '{print $1}'`

treatmentsortedbam=`echo $treatmentbam|sed "s/.bam/.sorted.bam/g"`
inputsortedbam=`echo $inputbam|sed "s/.bam/.sorted.bam/g"`

cpus=`nproc`

dx-docker run -v /data/:/data kopardev/ccbr_samtools_1.9 samtools sort -@ $cpus -o $treatmentsortedbam $treatmentbam
dx-docker run -v /data/:/data kopardev/ccbr_samtools_1.9 samtools sort -@ $cpus -o $inputsortedbam $inputbam

dx-docker run -v /data/:/data kopardev/ccbr_samtools_1.9 samtools index $treatmentsortedbam
dx-docker run -v /data/:/data kopardev/ccbr_samtools_1.9 samtools index $inputsortedbam

dx-docker run -v /data/:/data kopardev/ccbr_deeptools_3.1.2 bamCoverage --bam $treatmentsortedbam -o $treatmentbw --binSize 25 --smoothLength 75 --ignoreForNormalization chrX chrY chrM --numberOfProcessors $cpus --normalizeUsing RPGC --effectiveGenomeSize $genomesize --extendReads $treatmentextsize
dx-docker run -v /data/:/data kopardev/ccbr_deeptools_3.1.2 bamCoverage --bam $inputsortedbam -o $inputbw --binSize 25 --smoothLength 75 --ignoreForNormalization chrX chrY chrM --numberOfProcessors $cpus --normalizeUsing RPGC --effectiveGenomeSize $genomesize --extendReads 200


    # Fill in your application code here.
    #
    # To report any recognized errors in the correct format in
    # $HOME/job_error.json and exit this script, you can use the
    # dx-jobutil-report-error utility as follows:
    #
    #   dx-jobutil-report-error "My error message"
    #
    # Note however that this entire bash script is executed with -e
    # when running in the cloud, so any line which returns a nonzero
    # exit code will prematurely exit the script; if no error was
    # reported in the job_error.json file, then the failure reason
    # will be AppInternalError with a generic error message.

    # The following line(s) use the dx command-line tool to upload your file
    # outputs after you have created them on the local file system.  It assumes
    # that you have used the output field name for the filename for each output,
    # but you can change that behavior to suit your needs.  Run "dx upload -h"
    # to see more options to set metadata.

    TreatmentBigwig=$(dx upload /data/$treatmentbw --brief)
    InputBigwig=$(dx upload /data/$inputbw --brief)

    # The following line(s) use the utility dx-jobutil-add-output to format and
    # add output variables to your job's output as appropriate for the output
    # class.  Run "dx-jobutil-add-output -h" for more information on what it
    # does.

    dx-jobutil-add-output TreatmentBigwig "$TreatmentBigwig" --class=file
    dx-jobutil-add-output InputBigwig "$InputBigwig" --class=file
}
