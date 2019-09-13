#!/bin/bash

AUTH_DIR=~/.sdm-cli
AUTH_FILE=$AUTH_DIR/auth

SDM_CLI_DIR=$( dirname $(realpath $0) )

if [ "$1" == "-r" ]; then
    if [ ! -f $AUTH_FILE ]; then
        echo "Access key not stored. Please authenticate." >&2
        exit 1
    fi

    EXPIRATION_DATE=$(cat $AUTH_FILE | grep expiration_date | cut -d":" -f2)
    ACCESS_KEY=$(cat $AUTH_FILE | grep access_key | cut -d":" -f2)

    if (( $(date +%s) > $EXPIRATION_DATE )); then
        echo "Access key expired. Please authenticate again." >&2
        exit 1
    fi
    echo $ACCESS_KEY
    exit
fi

if (( $# < 1 )); then
    echo "Usage:"
    echo -e "     sdm-authenticate.sh <USERNAME> [-x]"
    echo -e "     sdm-authenticate.sh -r"
    echo -e "Options:"
    echo -e "    -r\tRevalidate stored access key"
    echo -e "    -x\tPrint XML result"
    exit 1
fi

USERNAME=$1; shift
echo -n "Password for $USERNAME: "; read -s PASSWORD
echo
ARGS=$@

SDM_HOST=$($SDM_CLI_DIR/sdm-config.sh -h)
TOKEN=$(echo "$USERNAME:$PASSWORD" | base64)

RESPONSE=$(curl -s \
   -H "Authorization: Basic $TOKEN" \
   -H "Content-Type: application/xml" \
   -d "<rest_access/>" \
   $SDM_HOST/caisd-rest/rest_access)

ACCESS_KEY=$(echo $RESPONSE | sed "s/.*access_key>\([0-9]\+\).*/\1/g")
EXPIRATION_DATE=$(echo $RESPONSE | sed "s/.*expiration_date>\([0-9]\+\).*/\1/g")

if [ -n "$(echo $ACCESS_KEY | sed s/[0-9]*//g)" ]; then
    echo "Authentication failure." >&2
    exit 1
fi

mkdir -p $AUTH_DIR
echo "access_key: $ACCESS_KEY" > $AUTH_FILE
echo "expiration_date: $EXPIRATION_DATE" >> $AUTH_FILE

if [ "$ARGS" == "-x" ]; then
    echo $RESPONSE
else
    echo $ACCESS_KEY
fi
