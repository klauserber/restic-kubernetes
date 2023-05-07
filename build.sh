#!/usr/bin/env sh

. ./VERSION

docker build . \
    --build-arg IMAGE_VERSION=${VERSION} \
    -t isi006/${IMAGE_NAME}:latest \
    -t isi006/${IMAGE_NAME}:${VERSION}
