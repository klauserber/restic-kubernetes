#!/bin/sh

function backup_on_exit() {
  echo "Shutdown... backup on exit"
  /backup.sh
}

if [ ${RESTIC_BACKUP_ON_EXIT} == 1 ]; then
  trap backup_on_exit SIGTERM
fi

echo "Starting..."

export RESTIC_HOST=${RESTIC_HOST:-${HOSTNAME}}

RESTORED_MARKER_FILE=${RESTIC_DATA_DIR}/restic-restored.txt

# check for existance/sanity of repo
restic snapshots &>/dev/null
repo_status=$?

# initialize repo if it doesn't exist or is malformed
if [ $repo_status != 0 ]; then
  echo "Initializing restic repository at '${RESTIC_REPOSITORY}'..."
  restic init
  init_status=$?

  if [ $init_status != 0 ]; then
    echo "Failed to initialize restic repository."
    exit 1
  fi
fi

if [ ${RESTIC_RESTORE} == 1 ]; then
  if [ ! -f ${RESTORED_MARKER_FILE} ]; then
    echo "Restore is requested and the file '${RESTORED_MARKER_FILE}' is not present -> going to restore."
    /restore.sh ${RESTIC_RESTORE_SNAPSHOT} --target / 
    echo "
      The presents of this file shows, that this volume was initialy restored.
      Removing this file leads to a full restore on the next container start." > ${RESTORED_MARKER_FILE}
  else
    echo "Restore is requested and the file '${RESTORED_MARKER_FILE}' is present -> skip restore."
  fi
else
    echo "Restore is not requested -> skip restore."
fi

echo "${BACKUP_CRON} /backup.sh >> /var/log/cron.log 2>&1" > /var/spool/cron/crontabs/root
echo "${CHECK_CRON} /check.sh >> /var/log/cron.log 2>&1" >> /var/spool/cron/crontabs/root

# ensure file exists, default CMD is to tail this file
touch /var/log/cron.log


# start cron daemon
crond

tail -fn0 /var/log/cron.log &

echo "Container setup complete."
wait $!
