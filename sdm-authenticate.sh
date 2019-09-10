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

if [ "$ARGS" == "-x" ]; then
    echo $RESPONSE
else
    echo $RESPONSE | sed "s/.*access_key>\([0-9]\+\).*/\1/g"
fi

if [ -z "$(echo $RESPONSE | grep access_key)" ]; then
   exit 1
fi
