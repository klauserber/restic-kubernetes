#!/bin/sh

. init.inc.sh

function backup_on_exit() {
  echo "Shutdown... backup on exit"
  ./backup.sh
}

if [ ${RESTIC_BACKUP_ON_EXIT} == 1 ]; then
  trap backup_on_exit SIGTERM
fi

echo "Starting... image version ${IMAGE_VERSION}"

export RESTIC_HOST=${RESTIC_HOST:-${HOSTNAME}}

echo "unlock at startup"
restic unlock

echo -n "check for existence/sanity of repo, status: "
restic snapshots &>/dev/null
repo_status=$?

echo $repo_status

if [ $repo_status != 0 ] && [ ${RESTIC_RESTORE} == 1 ]; then
  echo "Restore is requested but the repository '${RESTIC_REPOSITORY}' does not exists, assuming starting from scratch -> skip restore."
  markRestored
  exit 0
fi

# initialize repo if it doesn't exist or is malformed
if [ $repo_status != 0 ]; then
  echo "Initializing restic repository at '${RESTIC_REPOSITORY}'..."
  ./restic init
  init_status=$?

  if [ $init_status != 0 ]; then
    echo "Failed to initialize restic repository."
    exit 1
  fi
fi

if [ ${RESTIC_RESTORE} == 1 ]; then
  if [ ! -f ${RESTORED_MARKER_FILE} ]; then
    echo "Restore is requested and the file '${RESTORED_MARKER_FILE}' is not present -> going to restore."
    ./restore.sh ${RESTIC_RESTORE_SNAPSHOT} --target /
  else
    echo "Restore is requested and the file '${RESTORED_MARKER_FILE}' is present -> skip restore."
  fi
else
  if [ ${RESTIC_INSTANT_BACKUP} == 1 ]; then
    echo "Instant backup is requested -> going to backup."
    ./backup.sh
  else
    echo "Continues backup is requested -> configure cron and keep running."

    echo "${BACKUP_CRON} cd / && ./backup.sh >> /var/log/cron.log 2>&1" > /var/spool/cron/crontabs/root
    echo "${CHECK_CRON} cd / && ./check.sh >> /var/log/cron.log 2>&1" >> /var/spool/cron/crontabs/root

    # ensure file exists, default CMD is to tail this file
    touch /var/log/cron.log

    # start cron daemon
    crond

    tail -fn0 /var/log/cron.log &

    echo "Container setup complete."
    wait $!
  fi
fi
