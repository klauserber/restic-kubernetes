#!/bin/sh

export RESTIC_HOST=${RESTIC_HOST:-${HOSTNAME}}

restic restore --host ${RESTIC_HOST} ${@}
