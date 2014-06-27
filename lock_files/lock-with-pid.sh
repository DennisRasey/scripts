
WORK_DIR=$(dirname $(readlink -f $0))

MY_LOG=$WORK_DIR/somelog.log

## ensure only one instance is running
LOCK_FILE="$WORK_DIR/`basename "$0" .sh`.lck"
if [ ! -e "$LOCK_FILE" ]; then
  trap "rm -f $LOCK_FILE ; exit" INT TERM EXIT
  touch "$LOCK_FILE" ; echo "$$" > "$LOCK_FILE"
else  
  OLD_PID=`cat $LOCK_FILE 2> /dev/null`
   if [ "$OLD_PID" = "" ] ; then
      echo "$MY_DATE - $LOCK_FILE found, but it's empty, I'm bailing..." | tee -a "$MY_LOG"
      exit 1
   fi
   if ! kill -0 "$OLD_PID" &>/dev/null; then
      # lock is stale, remove it and continue
      echo "$MY_DATE - removing stale lock file $LOCK_FILE of nonexistant PID $OLD_PID" >> "$MY_LOG"
      rm -f "$LOCK_FILE" ; touch "$LOCK_FILE" ; echo "$$" > "$LOCK_FILE"
      trap "rm -f $LOCK_FILE ; exit" INT TERM EXIT      
   else
      # lock is valid and OLD_PID is active - exit, we're locked!
      echo "$MY_DATE - $0 already running on PID $OLD_PID" >> "$MY_LOG" ; exit 1
   fi  
fi


rm -f "$LOCK_FILE" ; trap - INT TERM EXIT

