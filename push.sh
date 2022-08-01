#!/usr/bin/env bash

. ./VERSION

docker push \
    isi006/${IMAGE_NAME}:latest

docker push \
    isi006/${IMAGE_NAME}:${VERSION}
