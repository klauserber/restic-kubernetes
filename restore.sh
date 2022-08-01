#!/bin/sh

restic restore --host ${RESTIC_HOST} ${@}
