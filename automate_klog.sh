#!/bin/bash

if [[ $# -eq 2 ]]
then
	LCwscount=0
	nonLCwscount=0
	totalcount=0
	missingcount=0
	KLOGFILE=$1
	TLOGFILE=$2
	FILEDATE=`echo $KLOGFILE|cut -d"." -f3`
	firstfile=`echo $KLOGFILE|cut -d"-" -f1|tr -d "\""|tr -d " "`
	Searchfile=`echo $TLOGFILE|cut -d"-" -f1|tr -d "\""|tr -d " "`
	TLOGBIN=`echo $firstfile\_$FILEDATE|tr -d "\""|tr -d " "`

    printf "\n$TLOGBIN\n"
	mkdir -p C:/Users/Klog_Bin/$FILEDATE/Base64_files
	CUR_DIR=$PWD
	printf "\n\nPicking CorrelationId from $firstfile error xml file and searching them in $Searchfile error xml file\n\n"
    
	echo "DATE,CORRELATION_ID,DIVISION,STORE,PRESENT_IN_(TLOG/KLOG)_ERROR_XML,STATUS,COMMENT" >klog_report_$FILEDATE.csv
#	echo "DATE,CORRELATION_ID,DIVISION,STORE,PAYLOAD" >nonlCwsrecords_$FILEDATE.txt
    cut -d"=" -f3 $TLOGFILE|sed 's/ApplicationRequestId//'|while read CorrelationId 
	do
		found=`grep $CorrelationId $TLOGFILE`
		record=`grep $CorrelationId $KLOGFILE`
		cid=`echo $CorrelationId|tr -d "\""`
		Division1=`echo $found|cut -d"=" -f5|sed 's/Store//'|tr -d "\""|tr -d " "`
		Store1=`echo $found|cut -d"=" -f6|cut -d">" -f1|tr -d "\""|tr -d " "`
		base64payload1=`echo $found|awk -F'base64' '{print $3}'|cut -d">" -f2|cut -d"<" -f1`
		totalcount=`expr $totalcount + 1`
		if [ -z $record ] 
		then
			printf "\nIn KLOG missing"
			
			missingcount=`expr $missingcount + 1`
			printf "\nNot present in $Searchfile error xml file $cid\n" 
			printf "\nGetting Payload for $cid\n"
			mkdir -p C:/Users/Klog_Bin/$FILEDATE/Missing_Payload_Bins
			TLOGbinfile=`echo $TLOGBIN\_$cid\_$Division1\_$Store1`
			printf "\nCreating base64 file $TLOGbinfile.base64 \n\n"
		   			
			echo $base64payload1 > C:/Users/Klog_Bin/$FILEDATE/Base64_files/$TLOGbinfile.base64
			
			printf "\nCreating TLOG binary file $TLOGbinfile.bin from base64 file $TLOGbinfile.base64 \n\n"
			
			base64 -d C:/Users/Klog_Bin/$FILEDATE/Base64_files/$TLOGbinfile.base64 > C:/Users/Klog_Bin/$FILEDATE/Missing_Payload_Bins/$TLOGbinfile.bin
			RC=$?	
			if [[ $RC -eq 0 ]]
			then
			
				printf "\nSuccessfully created TLOG binary file $TLOGbinfile.bin for CorrelationId $cid \n"
			
			else
			
				printf "\nERROR occured while creating TLOG binary file $TLOGbinfile.bin for CorrelationId $cid \n"
			
			fi
			
			validrecords=`echo $FILEDATE\,$cid\,$Division1\,$Store1\,Present In Tlog\,Invalid\,Looks like regular payload.Present in Tlog.`
			echo $validrecords>>klog_report_$FILEDATE.csv
			printf "Current Record Count of Total Processed = $totalcount, LCws = $LCwscount, Non LCws = $nonLCwscount, Missing from $Searchfile = $missingcount  \n\n"
		fi
	done
			
	cut -d"=" -f3 $KLOGFILE|sed 's/ApplicationRequestId//'|while read CorrelationId

	do
		found=`grep $CorrelationId $TLOGFILE`
		record=`grep $CorrelationId $KLOGFILE`
		cid=`echo $CorrelationId|tr -d "\""`
		Division=`echo $record|cut -d"=" -f5|sed 's/Store//'|tr -d "\""|tr -d " "`
		Store=`echo $record|cut -d"=" -f6|cut -d">" -f1|tr -d "\""|tr -d " "`
		base64payload=`echo $record|awk -F'base64' '{print $3}'|cut -d">" -f2|cut -d"<" -f1`
		totalcount=`expr $totalcount + 1`
		
		
		if [ -z $found ]
		then
			printf "\nIn TLOG missing"
			missingcount=`expr $missingcount + 1`
			printf "\nNot present in $firstfile error xml file $cid\n" 
			printf "\nGetting Payload for $cid\n"
			mkdir -p C:/Users/Klog_Bin/$FILEDATE/Missing_Payload_Bins
			TLOGbinfile=`echo $TLOGBIN\_$cid\_$Division\_$Store`
			printf "\nCreating base64 file $TLOGbinfile.base64 \n\n"
		   			
			echo $base64payload > C:/Users/Klog_Bin/$FILEDATE/Base64_files/$TLOGbinfile.base64
			
			printf "\nCreating TLOG binary file $TLOGbinfile.bin from base64 file $TLOGbinfile.base64 \n\n"
			
			base64 -d C:/Users/Klog_Bin/$FILEDATE/Base64_files/$TLOGbinfile.base64 > C:/Users/Klog_Bin/$FILEDATE/Missing_Payload_Bins/$TLOGbinfile.bin
			RC=$?	
			if [[ $RC -eq 0 ]]
			then
			
				printf "\nSuccessfully created TLOG binary file $TLOGbinfile.bin for CorrelationId $cid \n"
			
			else
			
				printf "\nERROR occured while creating TLOG binary file $TLOGbinfile.bin for CorrelationId $cid \n"
			
			fi
			
			validrecords=`echo $FILEDATE\,$cid\,$Division\,$Store\,Present In Klog\,InValid\,Looks like regular payload.Present in Klog.`
			echo $validrecords>>klog_report_$FILEDATE.csv
			printf "Current Record Count of Total Processed = $totalcount, LCws = $LCwscount, Non LCws = $nonLCwscount, Missing from $firstfile = $missingcount  \n\n"
		
		else
			printf "\nPresent in $Searchfile XML file $cid\n"
			errorstring="LCws"
			if [[ "$base64payload" == *"$errorstring"* ]]
			then
				mkdir -p C:/Users/Klog_Bin/$FILEDATE/Lcws_Bins
				TLOGbinfile=`echo $TLOGBIN\_$cid\_$Division\_$Store`
			    printf "\nCreating base64 file $TLOGbinfile.base64 \n\n"
			    echo $base64payload > C:/Users/Klog_Bin/$FILEDATE/Base64_files/$TLOGbinfile.base64
			
			    printf "\nCreating TLOG binary file $TLOGbinfile.bin from base64 file $TLOGbinfile.base64 \n\n"
		         
			    base64 -d C:/Users/Klog_Bin/$FILEDATE/Base64_files/$TLOGbinfile.base64 > C:/Users/Klog_Bin/$FILEDATE/Lcws_Bins/$TLOGbinfile.bin
	
				LCwscount=`expr $LCwscount + 1`
				printf "Payload for CorrelationId = $cid, Division = $Division, Store = $Store has LCws charecters \n"
				printf "Current Record Count of Total Processed = $totalcount, LCws = $LCwscount, Non LCws = $nonLCwscount, Missing from $Searchfile = $missingcount  \n\n"
				LCwsrecords=`echo $FILEDATE\,$cid\,$Division\,$Store\,Both\,Invalid\,Repeated LCws characters.`
				echo $LCwsrecords>>klog_report_$FILEDATE.csv
			
			else
				mkdir -p C:/Users/Klog_Bin/$FILEDATE/Regular_Payload_Bins
				TLOGbinfile=`echo $TLOGBIN\_$cid\_$Division\_$Store`
			    printf "\nCreating base64 file $TLOGbinfile.base64 \n\n"
		
			    echo $base64payload > C:/Users/Klog_Bin/$FILEDATE/Base64_files/$TLOGbinfile.base64
			
			    printf "\nCreating TLOG binary file $TLOGbinfile.bin from base64 file $TLOGbinfile.base64 \n\n"
			
			    base64 -d C:/Users/Klog_Bin/$FILEDATE/Base64_files/$TLOGbinfile.base64 > C:/Users/Klog_Bin/$FILEDATE/Regular_Payload_Bins/$TLOGbinfile.bin
				nonLCwscount=`expr $nonLCwscount + 1`
				printf "Payload for CorrelationId = $cid, Division = $Division, Store = $Store do not have LCws charecters \n"
				printf "Current Record Count of Total Processed = $totalcount, LCws = $LCwscount, Non LCws = $nonLCwscount, Missing from $Searchfile = $missingcount  \n\n"
				nonLCwsrecord=`echo $FILEDATE\|$cid\|$Division\|$Store\|$base64payload|tr -d "\""`
#				echo $nonLCwsrecord>>nonLCwsrecords_$FILEDATE.txt
				nonLCwsrecords=`echo $FILEDATE\,$cid\,$Division\,$Store\,Both\,Invalid\,Looks like regular payload. But present in both files.`
				echo $nonLCwsrecords>>klog_report_$FILEDATE.csv 
			    
			fi
		fi
	
	done
	
	printf "\nPlease review \"klog_report_$FILEDATE.csv\" to check All records"
	printf "\nPlease review this file \"nonlCwsrecords_$FILEDATE.txt\" to check the Non LCws records"
	printf "\nPlease run this rm nonlCwsrecords_$FILEDATE.txt klog_report_$FILEDATE.csv to remove the files to rerun"
	rmdir C:/Users/Klog_Bin/$FILEDATE/Base64_files

else
	
	echo "Need to pass two parameters to automate_klog.sh"
	echo "For example ./automate_klog.sh klog-parse-errors.xml.YYYY-MM-DD tlog-parse-errors.xml.YYYY-MM-DD"

fi
