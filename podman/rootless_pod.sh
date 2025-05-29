#!/bin/bash

HOSTNAME_VAR=$(hostname)

podman pod create \
  --name rootless_pod \
  --hostname $HOSTNAME_VAR \
  --security-opt no-new-privileges \
  -p 25:25 \
  -p 110:110 \
  -p 143:143 \
  -p 995:995 \
  -p 993:993 \
  -p 587:587 \
  -p 2424:2424 \
  -p 12345:12345 \
  -p 6379:6379 \
  -p 8888:8888 \
  -p 11332:11332 \
  -p 11334:11334 \
  -p 3306:3306
