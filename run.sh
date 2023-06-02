#!/usr/bin/env bash

. ./VERSION

docker run -it --rm --name restic --hostname restic-test \
    -p 8001:8001 \
    -v $(pwd)/testrepo:/repo \
    -v $(pwd)/testdata:/data \
    isi006/${IMAGE_NAME}:latest
