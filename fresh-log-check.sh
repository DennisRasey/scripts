#!/bin/sh

APP_NAME=tibco
LOG_FILE=/opt/jboss/stable/server/$APP_NAME/server.log

## in minutes
TIME_OUT=2
FAIL_LIMIT=3

## where to send alerts
EMAIL_LIST="me@example.com"
PAGER_LIST="me-pager@example.com"

WORK_DIR=$(dirname $(readlink -f $0))
MY_LOG="$WORK_DIR/$APP_NAME-check.log"
MY_DATE=`date +%F" "%T`
MY_HOST=`hostname -s`
MY_STATE="$WORK_DIR/$APP_NAME.state"

## ensure only one instance is running
LOCK_FILE="$WORK_DIR/`basename "$0" .sh`.lck"
if [ ! -e "$LOCK_FILE" ]; then
  trap "rm -f $LOCK_FILE ; exit" INT TERM EXIT ; touch "$LOCK_FILE"
else
  echo "$MY_DATE - already running" >> "$MY_LOG" ; exit 1
fi


dateDiff () {

   unset TIME_DIFF
   dte1=`date --utc --date "$1" +%s`
   dte2=`date --utc --date "$2" +%s`
   diffSec=$((dte2-dte1))
   if ((diffSec < 0)); then abs=-1; else abs=1; fi
   TIME_DIFF=$((diffSec/1*abs))
   echo "$TIME_DIFF"

}


alerter () {
 
   MSG="$APP_NAME log has stopped updating on $MY_HOST"
   echo "$MY_DATE - $MSG" >> "$MY_LOG"
   echo "$MSG - log file has not updated in over $TIME_OUT min" | mail -s "$MSG" -c "$EMAIL_LIST" "$PAGER_LIST"    
   
}


LAST_STATE_CHECK () {
   
   COUNT=0
   if [ ! -e $MY_STATE ] ; then
      COUNT=1 ; echo $COUNT > "$MY_STATE"
   else      
      COUNT=`cat $MY_STATE`
      if [ $COUNT -lt $FAIL_LIMIT ] ; then
         COUNT=$((COUNT +1)) ; echo $COUNT > "$MY_STATE"
      else
         COUNT=0 ; echo $COUNT > "$MY_STATE" ; alerter
      fi
   fi
   
}


## date format in log file
MY_LOG_DATE=`date +%D" "%r`

## find last log entry w/date
LAST_TIME=`tac "$LOG_FILE" | grep -m1 "$MY_LOG_DATE" | awk '{print $1" "$2}' `

MY_DIFF=`dateDiff "$MY_DATE" "$LAST_TIME"`

## check if the file's age is older then TIME_OUT
if [ $MY_DIFF -gt $((TIME_OUT * 60)) ] ; then
   echo "$MY_DATE - $MY_DIFF" >> "$MY_LOG" ; LAST_STATE_CHECK
else
   COUNT=0 ; echo $COUNT > "$MY_STATE"
fi

rm -f "$TMP_FILE"
rm -f "$LOCK_FILE" ; trap - INT TERM EXIT

exit 0

