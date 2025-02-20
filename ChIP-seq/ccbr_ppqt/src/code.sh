#!/bin/bash
# ccbr_ppqt 0.0.1
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

    echo "Value of InBam: '$InBam'"

    # The following line(s) use the dx command-line tool to download your file
    # inputs to the local file system using variable names for the filenames. To
    # recover the original filenames, you can use the output of "dx describe
    # "$variable" --name".

mkdir -p /data
cd /data
cpus=`nproc`

sarfile="/data/${DX_JOB_ID}_sar.txt"
sar 5 > $sarfile &
SAR_PID=$!

t_tagalign=$(dx describe "$InBam" --name)
dx download "$InBam" -o $t_tagalign

ppqt=${t_tagalign}.ppqt
pdf=${ppqt}.pdf

dx-docker run -v /data/:/data nciccbr/ccbr_spp_1.14:v032219 run_spp.R -c=$t_tagalign -out=$ppqt -savp=$pdf

(>&2 echo "DEBUG:Listing all files in data")
(>&2 ls -larth)
(>&2 echo "Done listing")

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

    OutPdf=$(dx upload /data/$pdf --brief)
    OutPpqt=$(dx upload /data/$ppqt --brief)

    # The following line(s) use the utility dx-jobutil-add-output to format and
    # add output variables to your job's output as appropriate for the output
    # class.  Run "dx-jobutil-add-output -h" for more information on what it
    # does.

    dx-jobutil-add-output OutPdf "$OutPdf" --class=file
    dx-jobutil-add-output OutPpqt "$OutPpqt" --class=file

    kill -9 $SAR_PID
    SarTxt=$(dx upload $sarfile --brief)
    dx-jobutil-add-output SarTxt "$SarTxt" --class=file
}
