#!/bin/sh

export RESTIC_HOST=${RESTIC_HOST:-${HOSTNAME}}

RESTORED_MARKER_FILE=${RESTIC_DATA_DIR}/restic-restored.txt

echo "Starting restore at $(date +"%Y-%m-%d %H:%M:%S") (image version ${IMAGE_VERSION}))"
start=`date +%s`

restic restore --host ${RESTIC_HOST} ${@}

echo "
  The presents of this file shows, that this volume was initialy restored.
  Removing this file leads to a full restore on the next container start." > ${RESTORED_MARKER_FILE}

end=`date +%s`
echo "Finished restore at $(date +"%Y-%m-%d %H:%M:%S") after $((end-start)) seconds"