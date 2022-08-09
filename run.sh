#!/usr/bin/env bash

. ./VERSION

docker run -it --rm --name restic --hostname restic-test \
    -v $(pwd)/testrepo:/repo \
    isi006/${IMAGE_NAME}:latest
