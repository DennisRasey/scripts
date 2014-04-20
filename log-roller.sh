#!/bin/sh

## 'home' directory where the jboss apps reside
LOG_DIR="/opt/jboss/stable/server/"

## compressed logs older then this
COMPRESS_AGE=7

## delete compressed logs older then this
DEL_AGE=90


## where to store output; this will include which files were compressed and which files were deleted
WORK_DIR=$(dirname $(readlink -f $0))
LOG_FILE="$WORK_DIR/log-roller.log"

MY_DATE=`date +%F" "%T`

## ensure only one instance is running
LOCK_FILE="$WORK_DIR/`basename "$0" .sh`.lck"
if [ ! -e "$LOCK_FILE" ]; then
  trap "rm -f $LOCK_FILE ; exit" INT TERM EXIT ; touch "$LOCK_FILE"
else
  echo "$MY_DATE - already running" >> "$MY_LOG" ; exit 1
fi


cd "$LOG_DIR"

## find all wrapper.log files & empty them
## delete all old/compressed wrapper.log files (if they exist)
find . -type f -name "wrapper.log" -not -name "*.gz" -exec tee {} </dev/null \;
find . -type f -name "wrapper.log.*" -exec rm {} \;

echo >> "$LOG_FILE"

## find all *.gz (f)iles older then $DEL_AGE, first "print" filename to log, then delete it
echo "$MY_DATE - Deleting these files from `pwd`:" >> "$LOG_FILE"
find . -type f -name "*.gz" -mtime +$DEL_AGE -print >> "$LOG_FILE"
find . -type f -name "*.gz" -mtime +$DEL_AGE -exec rm -f {} \;
echo "Done." >> "$LOG_FILE" ; echo >> "$LOG_FILE"


## find all "rolled" log files (i.e. server.log.2008-11-24), first "print" filename to log, then gzip the file
echo "$MY_DATE - compressing these files from `pwd`:" >> "$LOG_FILE"
find . -type f -name "*.log.*" -not -name "*.gz" -mtime +$COMPRESS_AGE -print >> "$LOG_FILE"
find . -type f -name "*.log.*" -not -name "*.gz" -mtime +$COMPRESS_AGE -exec gzip {} \;

echo "Done." >> "$LOG_FILE" ; echo >> "$LOG_FILE"

rm -f "$LOCK_FILE" ; trap - INT TERM EXIT

exit 0
