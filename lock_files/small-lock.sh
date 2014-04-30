
WORK_DIR=$(dirname $(readlink -f $0))


## ensure only one instance is running
LOCK_FILE="$WORK_DIR/`basename "$0" .sh`.lck"
if [ ! -e "$LOCK_FILE" ]; then
  trap "rm -f $LOCK_FILE ; exit" INT TERM EXIT ; touch "$LOCK_FILE"
else
  echo "$MY_DATE - already running" >> "$MY_LOG" ; exit 1
fi



rm -f "$LOCK_FILE" ; trap - INT TERM EXIT

