#!/bin/sh

cd /exporter
. ./venv/bin/activate

echo -n $RESTIC_PASSWORD > restic_password

export RESTIC_REPO_URL=$RESTIC_REPOSITORY
export RESTIC_REPO_PASSWORD_FILE=/exporter/restic_password

python restic-exporter.py
