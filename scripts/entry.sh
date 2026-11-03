#!/bin/sh

. ./init.inc.sh

backup_on_exit() {
  echo "Shutdown... backup on exit"
  ./backup.sh
}

# no automatic backups at all (also not on exit) when continuous backup is disabled
if [ "${RESTIC_BACKUP_ON_EXIT}" = "1" ] && [ "${RESTIC_CONT_BACKUP}" = "1" ]; then
  trap backup_on_exit SIGTERM
fi

echo "Starting... image version ${IMAGE_VERSION}"

export RESTIC_HOST=${RESTIC_HOST:-localhost}

# Without continuous backup this container only reads from the repository (e.g. a test system
# restored from prod, possibly sharing the prod repository): never unlock, init or check it
# automatically, as that would modify/interfere with the repository.
if [ "${RESTIC_CONT_BACKUP}" = "1" ]; then
  echo "unlock at startup"
  restic unlock
else
  echo "Continuous backup is disabled -> skip unlock at startup"
fi

echo -n "check for existence/sanity of repo, status: "
restic snapshots > /dev/null 2>&1
repo_status=$?

echo $repo_status

if [ $repo_status != 0 ] && [ "${RESTIC_RESTORE}" = "1" ]; then
  echo "Restore is requested but the repository '${RESTIC_REPOSITORY}' does not exists, assuming starting from scratch -> skip restore."
  markRestored
  exit 0
fi

# initialize repo if it doesn't exist or is malformed
if [ $repo_status != 0 ] && [ "${RESTIC_CONT_BACKUP}" != "1" ]; then
  echo "Repository '${RESTIC_REPOSITORY}' is missing or not readable, continuous backup is disabled -> skip init."
elif [ $repo_status != 0 ]; then
  echo "Initializing restic repository at '${RESTIC_REPOSITORY}'..."
  restic init
  init_status=$?

  if [ $init_status != 0 ]; then
    echo "Failed to initialize restic repository."
    exit 1
  fi
fi

if [ "${RESTIC_RESTORE}" = "1" ]; then
  if [ ! -f ${RESTORED_MARKER_FILE} ]; then
    echo "Restore is requested and the file '${RESTORED_MARKER_FILE}' is not present -> going to restore."
    ./restore.sh ${RESTIC_RESTORE_SNAPSHOT} --target /
  else
    echo "Restore is requested and the file '${RESTORED_MARKER_FILE}' is present -> skip restore."
  fi
else
  if [ "${RESTIC_INSTANT_BACKUP}" = "1" ]; then
    echo "Instant backup is requested -> going to backup."
    ./backup.sh
  else
    echo "Configure cron and keep running."

    # ensure file exists, default CMD is to tail this file
    touch /var/log/cron.log

    # install crontab via `crontab` (sets correct 0600 perms, cron refuses files
    # written directly with e.g. `echo > /var/spool/cron/crontabs/root`);
    # busybox crond passes the daemon's environment down to the jobs
    {
      if [ "${RESTIC_CONT_BACKUP}" = "1" ]; then
        echo "Continuous backup is enabled -> scheduling backups (${BACKUP_CRON})." >&2
        echo "${BACKUP_CRON} cd / && ./backup.sh >> /var/log/cron.log 2>&1"
        echo "${CHECK_CRON} cd / && ./check.sh >> /var/log/cron.log 2>&1"
      else
        echo "Continuous backup is disabled (RESTIC_CONT_BACKUP=${RESTIC_CONT_BACKUP}) -> no scheduled backup/check, on-demand only." >&2
      fi
    } | crontab -

    # start cron daemon
    crond
    tail -fn0 /var/log/cron.log &

    # the exporter reads the repository continuously (stats, locks, check) -> not with disabled continuous backup
    if [ "${RESTIC_CONT_BACKUP}" = "1" ]; then
      echo "Starting metrics exporter..."
      ./exporter.sh &
    else
      echo "Continuous backup is disabled -> not starting metrics exporter."
    fi

    echo "Container setup complete."
    wait
  fi
fi
