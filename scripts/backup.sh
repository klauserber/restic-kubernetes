#!/bin/sh

set -Eeou pipefail

. init.inc.sh

echo "Starting backup at $(date +"%Y-%m-%d %H:%M:%S") (image version ${IMAGE_VERSION}))"
echo "Current dir: $(pwd)"

waitForRestoreCompleted

start=`date +%s`

# Define the directory containing the scripts
dir="/pre-backup-scripts.d"

echo "Running pre-backup scripts from $dir"

# Check if the directory exists
if [ -d "$dir" ]; then
    # Change to the directory
    cd "$dir"

    # Loop over each script in the directory
    for file in *.sh
    do
        echo "Running $file"    
        sh ./"$file"
    done
else
    echo "Directory $dir does not exist"
fi

nice -n ${NICE_ADJUST} ionice -c ${IONICE_CLASS} -n ${IONICE_PRIO} \
    restic backup ${BACKUP_SOURCE} \
    --host ${RESTIC_HOST} \
    --exclude ${RESTORE_IN_PROGRESS_MARKER_FILENAME}

sleep 3

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

markRestored

end=`date +%s`
echo "Finished backup at $(date +"%Y-%m-%d %H:%M:%S") after $((end-start)) seconds"