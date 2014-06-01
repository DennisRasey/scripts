#!/bin/bash

## log file we want to "watch"
WATCH_LOG="/tmp/log-scraper/tmp/server.log"

## text pattern we want to watch for
SEARCH_PATTERN="OutOfMemoryError"

## brief "description" of the app
APP_NAME="my_app"

## Where to send alerts
EMAIL_LIST="me@example.com"
PAGER_LIST="me.page@example.com"

MY_DATE=`date +%F" "%T`
WORK_DIR=$(dirname $(readlink -f $0))
cd "$WORK_DIR"
MY_HOST=`hostname -s`

## define log file to use for output
MY_LOG="$WORK_DIR/logs/$APP_NAME.log"

## define location to store total number of lines in log file
NUMLINES_FILE="$WORK_DIR/tmp/$APP_NAME.lines"

## check if the log file we want to watch exists
test -e "$WATCH_LOG" || { echo "cannot find $WATCH_LOG" | tee -a "$MY_LOG" ; exit 1 ; }

## ensure only one instance is running
LOCK_FILE="$WORK_DIR/`basename "$0" .sh`.lck"
if [ ! -e "$LOCK_FILE" ]; then
  trap "rm -f $LOCK_FILE ; exit" INT TERM EXIT ; touch "$LOCK_FILE"
else
  echo "$MY_DATE - already running" >> "$MY_LOG" ; exit 1
fi

 
last_log_position () {

   WATCH_LOG="$1" ; NUMLINES_FILE="$2" ; NUMLINES_DIFF=0

   ## find total number of lines in the log file
   CUR_LINE_COUNT=`wc -l $WATCH_LOG | awk '{print $1}'`

   ## retrieve the previous line count of the log file
   ## if there isn't one, make a new one with the current line count
   if [ -r "$NUMLINES_FILE" ]; then
      OLD_LINE_COUNT=`cat "$NUMLINES_FILE"`
   else
      #echo "$CUR_LINE_COUNT" > "$NUMLINES_FILE"
      echo "0" > "$NUMLINES_FILE"
      OLD_LINE_COUNT=`cat "$NUMLINES_FILE"`
   fi
   
   echo "$CUR_LINE_COUNT" > "$NUMLINES_FILE"  ## save new line count

   if [ "$OLD_LINE_COUNT" -lt "$CUR_LINE_COUNT" ]; then
     NUMLINES_DIFF=$(($CUR_LINE_COUNT - $OLD_LINE_COUNT))
   elif [ "$OLD_LINE_COUNT" -eq "$CUR_LINE_COUNT" ]; then
     NUMLINES_DIFF=0  # log same size
   else
     NUMLINES_DIFF="$CUR_LINE_COUNT"  ## log rolled?
     echo "$MY_DATE - log rolled?" >> "$MY_LOG"
   fi
   
}

alerter () {

   ## find the "app" this log is for
   APP_LOG=`echo $1 | awk -F "/" '{print $6}'`

   ## define page format/syntax
   ## 2008-04-19 18:45:19 - search pattern 'dennis' found on HOSTNAME
   ALERT_MSG_SUBJECT="$MY_DATE - search pattern: '$SEARCH_PATTERN' found on $HOSTNAME"
   ALERT_MSG_BODY="$MY_DATE - search pattern: '$SEARCH_PATTERN' found on $HOSTNAME for $APP_LOG"

   echo "$ALERT_MSG_BODY" >> "$MY_LOG"
   echo "$ALERT_MSG_BODY" | mail -s "$ALERT_MSG_SUBJECT" -c "$EMAIL_LIST" "$PAGER_LIST"

}


last_log_position "$WATCH_LOG" "$NUMLINES_FILE"

if [ "$NUMLINES_DIFF" -ne 0 ] ; then
   tail -n "$NUMLINES_DIFF" "$WATCH_LOG" | if grep -q "$SEARCH_PATTERN" ; then 
      alerter "$WATCH_LOG"
   fi  
fi

rm -f "$LOCK_FILE" ; trap - INT TERM EXIT

exit 0

