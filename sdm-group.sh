#!/bin/bash

set -e

SDM_CLI_DIR=$( dirname $(realpath $0) )

if [ -z "$1" ]; then
    echo "Usage: sdm-group.sh <GROUP_NAME> [OPTIONS]"
    echo -e "Options:"
    echo -e "    -x\tPrint XML result"
    exit 1
fi

SDM_HOST=$($SDM_CLI_DIR/sdm-config.sh -g)
ACCESS_KEY=$($SDM_CLI_DIR/sdm-authenticate.sh -r)
GROUP_NAME=$1; shift
ARGS=$@

COMMON_NAME=$(echo $GROUP_NAME | sed "s/ /%20/g")

RESPONSE=$(curl -s \
    -H "X-AccessKey: $ACCESS_KEY" \
    "$SDM_HOST/caisd-rest/grp/COMMON_NAME-$COMMON_NAME")

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
