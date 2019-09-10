#!/bin/bash

if (( $# < 2 )); then
    echo "Usage: sdm-authenticate.sh <USERNAME> <PASSWORD> [OPTIONS]"
    echo -e "Options:"
    echo -e "    -x\tPrint full result"
    exit 1
fi

USERNAME=$1; shift
PASSWORD=$1; shift
ARGS=$@

TOKEN=$(echo "$USERNAME:$PASSWORD" | base64)

RESPONSE=$(curl -s \
   -H "Authorization: Basic $TOKEN" \
   -H "Content-Type: application/xml" \
   -d "<rest_access/>" \
   http://sjkap754:8050/caisd-rest/rest_access)

ACCESS_KEY=$(echo $RESPONSE | sed "s/.*access_key>\([0-9]\+\).*/\1/g")

if [ -n "$(echo $ACCESS_KEY | sed s/[0-9]*//g)" ]; then
    echo "Authentication failure." >&2
    exit 1
fi

if [ "$ARGS" == "-x" ]; then
    echo $RESPONSE
else
    echo $ACCESS_KEY
fi
