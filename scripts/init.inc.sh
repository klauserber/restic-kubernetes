
export RESTIC_HOST=${RESTIC_HOST:-${HOSTNAME}}

RESTORED_MARKER_FILE=${RESTIC_DATA_DIR}/restic-restored.txt
RESTORE_IN_PROGRESS_MARKER_FILENAME=restic-restore-inprogress.txt
RESTORE_IN_PROGRESS_MARKER_FILE=${RESTIC_DATA_DIR}/${RESTORE_IN_PROGRESS_MARKER_FILENAME}

RESTORED_TXT="
  The presents of this file shows, that this volume was initialy restored.
  Removing this file leads to a full restore on the next container start."

RESTORE_IN_PROGRESS_TXT="
  The presents of this file shows, that the restore process is currently running.
  Remove this file only if something went wrong during restore."


function markRestored {
  echo "${RESTORED_TXT}" > ${RESTORED_MARKER_FILE}
}

function markRestoreInProgress {
  echo "${RESTORE_IN_PROGRESS_TXT}" > ${RESTORE_IN_PROGRESS_MARKER_FILE}
}

function unmarkRestoreInProgress {
  if [ -f ${RESTORE_IN_PROGRESS_MARKER_FILE} ]; then
    rm ${RESTORE_IN_PROGRESS_MARKER_FILE}
  fi
}

function waitForRestoreCompletedAndExit {
  if [ -f ${RESTORE_IN_PROGRESS_MARKER_FILE} ]; then
    echo "Restore already in progress."
    while [ -f ${RESTORE_IN_PROGRESS_MARKER_FILE} ]; do
      echo "Waiting for completion ..."
      sleep 5
    done
    echo "Restore completed. Exit now."
    exit 0
  fi
}

function waitForRestoreCompleted {
  if [ -f ${RESTORE_IN_PROGRESS_MARKER_FILE} ]; then
    echo "Restore already in progress."
    while [ -f ${RESTORE_IN_PROGRESS_MARKER_FILE} ]; do
      echo "Waiting for completion ..."
      sleep 5
    done
    echo "Restore completed."
  fi
}
