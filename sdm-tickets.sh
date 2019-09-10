#!/bin/bash

set -e

MAX_RESULTS=10
ATTRIBUTES="status, priority, summary, open_date"
STATUS_NAME=Aberto

if [ -z "$3" ]; then
    echo "Usage: sdm-tickets.sh <USERNAME> <PASSWORD> <GROUP_NAME> [STATUS_NAME] [OPTIONS]"
    echo -e "STATUS_NAME:"
    echo -e "    The ticket status common name. Default value is $STATUS_NAME"
    echo -e "Options:"
    echo -e "    -x\tPrint full result"
    echo -e "    -a\tComma separated attribute names"
    echo -e "    \tDefault values are $ATTRIBUTES"
    exit 1
fi

USERNAME=$1; shift
PASSWORD=$1; shift
GROUP_NAME=$1; shift

while [ -n "$1" ]; do
    if [ "$1" == "-x" ]; then
        FULL_RESULT=1
        shift
        continue
    fi
    if [ "$1" == "-a" ]; then
        shift
        ATTRIBUTES=$(echo $1 | sed s/^all$/\*/g)
        shift
        continue
    fi
    STATUS_NAME=$1
    shift
done

ACCESS_KEY=$(./sdm-authenticate.sh $USERNAME $PASSWORD)

GROUP_ID=$(./sdm-group.sh $ACCESS_KEY "$GROUP_NAME")

if [ -n "$STATUS_NAME" ]; then
    STATUS_ID=$(./sdm-status.sh $ACCESS_KEY "$STATUS_NAME")
    STATUS_QUERY=" and status='$STATUS_ID'"
    STATUS_QUERY=$(echo $STATUS_QUERY | sed "s/ /%20/g" | sed "s/=/%3D/g")
fi

TICKETS=$(curl -s \
    -H "X-AccessKey: $ACCESS_KEY" \
    -H "X-Obj-Attrs: $ATTRIBUTES" \
    "http://sjkap754:8050/caisd-rest/in?start=1&size=$MAX_RESULTS&WC=group%3D'$GROUP_ID'$STATUS_QUERY")

echo $TICKETS | tidy -xml -qi --wrap 0
