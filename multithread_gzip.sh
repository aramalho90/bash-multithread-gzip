
  1
  2
  3
  4
  5
  6
  7
  8
  9
 10
 11
 12
 13
 14
 15
 16
 17
 18
 19
 20
 21
 22
 23
 24
 25
 26
 27
 28
 29
 30
 31
 32
 33
 34
 35
 36
 37
 38
 39
 40
 41
 42
 43
 44
 45
 46
 47
 48
 49
 50
 51
 52
 53
 54
 55
 56
 57
 58
 59
 60
 61
 62
 63
 64
 65
 66
 67
 68
 69
 70
 71
 72
 73
 74
 75
 76
 77
 78
 79
 80
 81
 82
 83
 84
 85
 86
 87
 88
 89
 90
 91
 92
 93
 94
 95
 96
 97
 98
 99
100
101
102
#!/bin/bash
#
#################################################################################################################
#														                                                        #
#	Author: André Ramalho											                                            #		
#														                                                        #
#	Usage: ./multithread_gzip.sh <DIR> <FILE_PATTERN> <NR_CORES> <LOG_DIR>                         				#
#														                                                        #
#	Description: This script will fork several gzip commands given a number of desired cores, a file pattern,   #
#    the input directory and a log directory.									                                #                      #                                                                                                               #   
#														                                                        #
#														                                                        #
#################################################################################################################


if [ $# -eq 0 ]; then
        echo "No arguments, the script will exit!"
    exit 1
fi

if [ ! -d "$1" ]; then
    echo "Invalid directory, the script will exit!"
    exit 1
fi

if [ ! -d "$4" ]; then
    echo "Invalid directory, the script will exit!"
    exit 1
fi

orig_dir="$(pwd)"
cd $1
file_pattern=$2
nr_cores=$3

if [ "$(ls $file_pattern 2> /dev/null | wc -l)" -eq "0" ];
then
	echo "No files found for pattern!"
	exit 1
fi

# Build aux file
touch filenames
for file in $file_pattern
do
	echo "$file" >> filenames
done

filecount="$(cat filenames | wc -l)"

while [ $filecount -gt 0 ]
do
	i=0
    head -n $nr_cores filenames | while read line # Launch <NR_CORES> gzip processes
 	do
        # Mark files as handled
		sed -i -e "s/$line//g" filenames
  		sed -i -e '/^\s*$/d' filenames
		gzip $line 2>>stderr &
		(( i++ ))
        
        # Wait for all background processes to end
		if [ $i -eq $nr_cores ];
		then
			wait
            		if [ "$( cat stderr | wc -l)" -gt 0 ];
	    			then	 # If a thread raised an error, abort
            			sysdate=`date +'%Y%m%d%H%M'`
            			logfile="$4/multithread_gzip_$sysdate.log"
				        timestamp=`date +'%d-%m-%Y %H:%M:%S'`
				        touch $logfile # Build a log file
                        echo "######################################################################################" >> $logfile
				        echo "[$timestamp] multithread_gzip.sh ended with the following message: " >>$logfile
            			cat stderr >> $logfile
            			echo "filenames:" >> $logfile
            			cat filenames >> $logfile
				        rm filenames
            			echo "File pattern: $file_pattern" >> $logfile
            			echo "Number of cores: $nr_cores" >> $logfile
            			echo "File count: $filecount" >> $logfile
				        break
            		fi
		fi
	done 
filecount="$(cat filenames 2> /dev/null | wc -l)"
done
rm filenames 2> /dev/null

if [ "$(cat stderr  | wc -l)" -gt 0 ];
then
	rm stderr
	echo "Terminated in error. Check the log file in $4 for more info."
	echo "Rolling back changes..."
	gunzip $file_pattern.gz
	echo "Done."
	cd $orig_dir
	exit 1
else
	rm stderr
	cd $orig_dir
	exit 0
fi
