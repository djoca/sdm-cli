#!/bin/bash

if [ -z "$1" ]; then
   echo "Usage: sdm-status.sh <ACCESS_KEY> <STATUS_NAME>"
   exit 0
fi

ACCESS_KEY=$1; shift
STATUS_NAME=$(echo $1 | sed "s/ /%20/g"); shift
ARGS=$@

COMMON_NAME=$(echo $STATUS_NAME | sed "s/ /%20/g")

RESPONSE=$(curl -s \
   -H "X-AccessKey: $ACCESS_KEY" \
   "http://sjkap754:8050/caisd-rest/crs/COMMON_NAME-$COMMON_NAME")

STATUS_ID=$(echo $RESPONSE | sed "s/.*REL_ATTR=\"\([^\"]*\)\".*/\1/g")

if [ -z "$STATUS_ID" ]; then
   echo "Status not found."
   exit 1
fi

if [ "$ARGS" == "-x" ]; then
    echo $RESPONSE
else
    echo $STATUS_ID
fi
