#!/bin/sh

export RESTIC_HOST=${RESTIC_HOST:-${HOSTNAME}}
RESTORED_MARKER_FILE=${RESTIC_DATA_DIR}/restic-restored.txt

echo "Starting backup at $(date +"%Y-%m-%d %H:%M:%S") (image version ${IMAGE_VERSION}))"
start=`date +%s`

nice -n ${NICE_ADJUST} ionice -c ${IONICE_CLASS} -n ${IONICE_PRIO} restic backup ${BACKUP_SOURCE} --host ${RESTIC_HOST}
BACKUP_RESULT=$?
if [[ $BACKUP_RESULT != 0 ]]; then
    echo "Backup failed with status ${BACKUP_RESULT}"
    restic unlock
    exit 1
fi

if [ -n "${RESTIC_FORGET_ARGS}" ]; then
    nice -n ${NICE_ADJUST} ionice -c ${IONICE_CLASS} -n ${IONICE_PRIO} restic forget ${RESTIC_FORGET_ARGS} --host ${RESTIC_HOST}
    FORGET_RESULT=$?
    if [[ $FORGET_RESULT != 0 ]]; then
        echo "Snapshot pruning failed with status ${FORGET_RESULT}"
        restic unlock
        exit 1
    fi
fi

echo "
  The presents of this file shows, that this volume was initialy restored.
  Removing this file leads to a full restore on the next container start." > ${RESTORED_MARKER_FILE}

end=`date +%s`
echo "Finished backup at $(date +"%Y-%m-%d %H:%M:%S") after $((end-start)) seconds"