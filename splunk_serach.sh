#!/bin/bash
#Author: Adam Delarosa 

CHECK=NAME_OF_CHECK
NUM3=3
IP=`ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}'`

#This will be run and send data to html, the data will check with PRTG and build log and diagram, if run 3 times with no data (or error data)- will stop and send mail.
for((i=1;i<4;i++)); do
#Add here the STRING "From source (include - to the end)"
#Add password, add username, add password,add address of splunk, add splunk search 
ID_NUMBER=`curl -s -u USERNAME:PASSWORD  -k https://xxx.xxx.xxx.xxx:xxxx/services/search/jobs -d search="SPLUNK SEARCH HERE" -d output_mode=csv -d earliest_time=-1h -d latest_time=now`;

#Dont change - this regular expression will output only the ID_NUMBER. the CURL will use it in his var.
ID_NUMBER=`echo $ID_NUMBER | awk '{gsub("/","",$0);split($0,arr,"<sid>"); print arr[2]}'`;

#Wait for ID_NUMBER to be updated.
sleep 10;

#Curl will use the ID_NUMBER given, so the COUNT + number display.
#Add user name, add password.
COUNT=`curl -u USERNAME:PASSWORD -k https://xxx.xxx.xxx.xxx:xxxx/services/search/jobs/$ID_NUMBER/results --get -d output_mode=csv "_time","avg(ExecTime)","_span" "_time","avg(ExecTime)","_span"`;

#Leave only data (NUMBER)
FINAL=`echo [$COUNT] | sed -e 's/\<count\>//g' | awk -F'"' '{print $10}' | xargs`;

#FINAL="2015-12-13T23:04:57.000+00:00" ## <==== WILL KILL THE STRING (TEST)


#if [ -n $FINAL ] ; then CHECK <== Only good to check if VAR equal to NULL.
#This will check if the number is int or double number, otherwise - will go to elif.
if  [[ $FINAL =~ ^[0-9]+\.[0-9]+$ ]] || [[ $FINAL =~ ^-?[0-9]+$ ]] ; then
	echo [$FINAL] > /usr/share/nginx/www/html/sample/splunk/count/ny/Rephrase_Average_Execution_Time_NY.html;
    echo "Count is OK: $FINAL";
    break;
elif [[ $i -eq $NUM3 ]]; then
 	echo "This is the $i check for $CHECK on $(date). string result is: [$FINAL]. sending email to sysadmin."
	mail -aFrom:email@addresss.com -s "Data read error: $CHECK" email@addresss.com<<< "There was an error while trying to read data from: $CHECK, date: $(date). id number: $ID_NUMBER . Count result: {$COUNT}. This was execute $i times, before sending this email error. please be advised, that the most recent check - will keep the last value. This mail sent to you by: $IP" 
else
	echo "Count is null or with error data. count = [$FINAL].This is a test number $i of 3.now will wait 15 secounds for next check of $CHECK.";
	sleep 5;
fi;
done;
