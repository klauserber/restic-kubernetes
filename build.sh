#!/usr/bin/env sh

. ./VERSION

docker build . \
    -t isi006/${IMAGE_NAME}:latest \
    -t isi006/${IMAGE_NAME}:${VERSION}
