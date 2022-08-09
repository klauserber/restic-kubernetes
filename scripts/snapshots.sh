#!/bin/sh
export RESTIC_HOST=${RESTIC_HOST:-${HOSTNAME}}

restic snapshots --host ${RESTIC_HOST}
