#!/bin/bash

if [ -z "$1" ]; then
   echo "Usage: sdm-group.sh <ACCESS_KEY> <GROUP_NAME>"
   exit 0
fi

ACCESS_KEY=$1; shift
GROUP_NAME=$(echo $1 | sed "s/ /%20/g"); shift
ARGS=$@

COMMON_NAME=$(echo $GROUP_NAME | sed "s/ /%20/g")

RESPONSE=$(curl -s \
   -H "X-AccessKey: $ACCESS_KEY" \
   "http://sjkap754:8050/caisd-rest/grp/COMMON_NAME-$COMMON_NAME")

GROUP_ID=$(echo $RESPONSE | sed "s/[^']*'\([A-F0-9]\+\).*/\1/g")

if [ -z "$GROUP_ID" ]; then
   echo "Group not found."
   exit 1
fi

if [ "$ARGS" == "-x" ]; then
    echo $RESPONSE
else
    echo $GROUP_ID
fi
