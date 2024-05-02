#!/bin/sh

. init.inc.sh

start=`date +%s`

echo "Check if restore is already in progress"

waitForRestoreCompletedAndExit

markRestoreInProgress

runScripts pre-restore.d

echo "Starting restore at $(date +"%Y-%m-%d %H:%M:%S") (image version ${IMAGE_VERSION}))"
restic restore --host ${RESTIC_HOST} ${@}

markRestored

unmarkRestoreInProgress

end=`date +%s`
echo "Finished restore at $(date +"%Y-%m-%d %H:%M:%S") after $((end-start)) seconds"

runScripts post-restore.d