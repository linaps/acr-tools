#!/bin/bash

# -------------------------------------------------------
#    >>  J Reyneke  |  ATIO Interactive  |  Nov '17  <<
# -------------------------------------------------------

# jobq_arcpending-feeder.sh is built to:
#
# -> 1 <-  determine the total count with lowest, highest unarchived recordings.
#   

####  Source common varuables and check the basics  

# MyDir=`dirname $0` ; source ${MyDir}../common/db.src || exit 1

#  am I postgres?
#  do I have eware credentials?
#  has ACR beed stopped?
#  collect stats to keep sane?
#  reccomend backup now>
#
####  ---------------------------

####  Local functions
#
#
####  ---------------------------

####  MAIN
#

printf "GET total_unarchived:\t"
total_unarchived=`psql eware -x -c "select count (*) as total_unarchived  from recordings where arcpending = 't' ; " | grep ^total_unarchived | awk '{print $3}'`
    echo $total_unarchived

printf "GET lowest_inum:\t"
lowest_inum=`psql eware -x -c "select inum as lowest_inum from recordings where arcpending = 't' order by inum asc limit 1; " | grep ^lowest_inum | awk '{print $3}'` && echo $lowest_inum

printf "GET highest_inum:\t"
highest_inum=`psql eware -x -c "select inum as highest_inum from recordings where arcpending = 't' order by inum desc limit 1; " | grep ^highest_inum | awk '{print $3}'` && echo $highest_inum

printf "GET last_jobid:\t"
last_jobid=`psql eware -x -c "select max(jobid) as last_jobid from jobqueue ; " | grep ^last_jobid | awk '{print $3}'` && echo $last_jobid

printf "\n\tINSERT one $lowest_inum [y/n] "
read INS ; printf "\n\n"
if [ $INS = "y" ]
then
    psql eware -c "insert into jobqueue (jobtype, inum, params, submitted, nparam) select 'ARCS', 0, recordings.inum, now(), 1 from recordings where recordings.inum = "$lowest_inum" ; select * from jobqueue ;"

    printf "\n\tINSERT rest of  $total_unarchived [y/n] "
    read INS2 ; printf "\n\n"
    if [ $INS2 = "y" ]
    then
        psql eware -c "insert into jobqueue (jobtype, inum, params, submitted, nparam)  select 'ARCS', 0, recordings.inum, now(), 1 from recordings where recordings.inum between "$lowest_inum" and "$highest_inum" and recordings.inum <> "$lowest_inum" and arcpending = 't'  ; select count (*) as total_jobs from jobqueue; select * from jobqueue order by jobid desc limit 5; select * from jobqueue order by jobid desc limit 5;"
    else
        echo
        echo "Not \"y\""
        exit 0
    fi
else
    echo
    echo "Not \"y\""
    exit 0
fi