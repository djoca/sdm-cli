#!/bin/bash

set -e

if [ -z "$1" ]; then
    echo "Usage: sdm-group.sh <GROUP_NAME> [OPTIONS]"
    echo -e "Options:"
    echo -e "    -x\tPrint full result"
    exit 1
fi

ACCESS_KEY=$(./sdm-authenticate.sh -r)
GROUP_NAME=$(echo $1 | sed "s/ /%20/g"); shift
ARGS=$@

COMMON_NAME=$(echo $GROUP_NAME | sed "s/ /%20/g")

RESPONSE=$(curl -s \
    -H "X-AccessKey: $ACCESS_KEY" \
    "http://sjkap754:8050/caisd-rest/grp/COMMON_NAME-$COMMON_NAME")

GROUP_ID=$(echo $RESPONSE | sed "s/[^']*'\([A-F0-9]\+\).*/\1/g")

if [ -z "$GROUP_ID" ]; then
    echo "Group not found." >&2
    exit 1
fi

if [ "$ARGS" == "-x" ]; then
    echo $RESPONSE
else
    echo $GROUP_ID
fi
