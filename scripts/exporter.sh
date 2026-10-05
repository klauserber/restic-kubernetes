#!/bin/sh

cd /exporter
. ./venv/bin/activate

# v2.x reads RESTIC_REPOSITORY and RESTIC_PASSWORD(_FILE/_COMMAND) directly from the environment
# RESTIC_HOST must not leak into the exporter: restic maps it to --host and would
# filter stats to snapshots of this host only, breaking global metrics
unset RESTIC_HOST
python -u exporter.py
