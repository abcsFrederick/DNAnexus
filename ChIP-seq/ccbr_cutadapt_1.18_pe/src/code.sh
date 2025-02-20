#!/bin/bash
# ccbr_cutadapt_1.18 0.0.1
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

    echo "Value of InFq1: '$InFq1'"
    echo "Value of InFq2: '$InFq2'"

    # The following line(s) use the dx command-line tool to download your file
    # inputs to the local file system using variable names for the filenames. To
    # recover the original filenames, you can use the output of "dx describe
    # "$variable" --name".

#    dx download "$InFq" -o InFq

cd /
(>&2 echo "DEBUG:Listing all files in root")
(>&2 ls -larth)
(>&2 echo "Done listing")


mkdir -p /data/
cp /TruSeq_and_nextera_adapters.consolidated.fa /data/
cd /data
(>&2 echo "DEBUG:Listing all files in data")
(>&2 ls -larth)
(>&2 echo "Done listing")

(>&2 echo "Downloading")

infq1=$(dx describe "$InFq1" --name)
dx download "$InFq1" -o $infq1
infq2=$(dx describe "$InFq2" --name)
dx download "$InFq2" -o $infq2

(>&2 echo "DEBUG:Listing all files in data")
(>&2 ls -larth)
(>&2 echo "Done listing")

outfile1name=`echo $infq1|sed "s/.fastq.gz/.trimmed.fastq.gz/g"`
outfile2name=`echo $infq2|sed "s/.fastq.gz/.trimmed.fastq.gz/g"`


dx-docker run -v /data/:/data kopardev/ccbr_cutadapt_1.18 cutadapt --pair-filter=both --nextseq-trim=2 --trim-n -n 5 -O 5 -q 10,10 -m 35:35 -b file:/data/TruSeq_and_nextera_adapters.consolidated.fa -B file:/data/TruSeq_and_nextera_adapters.consolidated.fa -j `nproc` -o $outfile1name -p $outfile2name $infq1 $infq2

(>&2 echo "DEBUG:Listing all files in data")
(>&2 ls -larth)
(>&2 echo "Done listing")

(>&2 echo "Uploading")

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

    OutFq1=$(dx upload /data/$outfile1name --brief)
	OutFq2=$(dx upload /data/$outfile2name --brief)

    # The following line(s) use the utility dx-jobutil-add-output to format and
    # add output variables to your job's output as appropriate for the output
    # class.  Run "dx-jobutil-add-output -h" for more information on what it
    # does.

    dx-jobutil-add-output OutFq1 "$OutFq1" --class=file
    dx-jobutil-add-output OutFq2 "$OutFq2" --class=file
}
