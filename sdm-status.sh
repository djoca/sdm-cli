#!/bin/bash

set -e

if [ -z "$1" ]; then
    echo "Usage: sdm-status.sh <STATUS_NAME> [OPTIONS]"
    echo -e "Options:"
    echo -e "    -x\tPrint XML result"
    exit 1
fi

ACCESS_KEY=$(./sdm-authenticate.sh -r)
STATUS_NAME=$(echo $1 | sed "s/ /%20/g"); shift
ARGS=$@

COMMON_NAME=$(echo $STATUS_NAME | sed "s/ /%20/g" | sed "s/\//_/g")

RESPONSE=$(curl -s \
    -H "X-AccessKey: $ACCESS_KEY" \
    "http://sjkap754:8050/caisd-rest/crs/COMMON_NAME-$COMMON_NAME")

STATUS_ID=$(echo $RESPONSE | sed "s/.*REL_ATTR=\"\([^\"]*\)\".*/\1/g")

if [ -z "$STATUS_ID" ]; then
    echo "Status not found." >&2
    exit 1
fi

if [ "$ARGS" == "-x" ]; then
    echo $RESPONSE
else
    echo $STATUS_ID
fi
