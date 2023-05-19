#!/usr/bin/env bash

. ./VERSION

docker run -it --rm --hostname restic-test \
    -e RESTIC_INSTANT_BACKUP=1 \
    -v $(pwd)/testrepo:/repo \
    -v $(pwd)/testdata:/data \
    isi006/${IMAGE_NAME}:latest
