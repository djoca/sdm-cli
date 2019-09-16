#!/bin/bash

set -e

SDM_CLI_DIR=$( dirname $(realpath $0) )

if [ -z "$1" ]; then
    echo "Usage: sdm-contact.sh <CONTACT_NAME> [OPTIONS]"
    echo -e "Options:"
    echo -e "    -x\tPrint XML result"
    exit 1
fi

SDM_HOST=$($SDM_CLI_DIR/sdm-config.sh -g)
ACCESS_KEY=$($SDM_CLI_DIR/sdm-authenticate.sh -r)
CONTACT_NAME=$(echo $1 | sed "s/ /%20/g"); shift
ARGS=$@

COMMON_NAME=$(echo $CONTACT_NAME | sed "s/ /%20/g" | sed "s/\//_/g")

RESPONSE=$(curl -s \
    -H "X-AccessKey: $ACCESS_KEY" \
    "$SDM_HOST/caisd-rest/cnt/COMMON_NAME-$COMMON_NAME")

CONTACT_ID=$(echo $RESPONSE | sed "s/[^']*'\([A-F0-9]\+\).*/\1/g")

if [ -z "$CONTACT_ID" ]; then
    echo "Contact not found." >&2
    exit 1
fi

if [ "$ARGS" == "-x" ]; then
    echo $RESPONSE | tidy -xml -qi -wrap 0
else
    echo $CONTACT_ID
fi
