#!/bin/bash

set -e

MAX_RESULTS=10
ATTRIBUTES="status, priority, summary, open_date"
STATUS_NAME=Aberto

if [ -z "$3" ]; then
    echo "Usage: sdm-tickets.sh <USERNAME> <PASSWORD> <GROUP_NAME> [OPTIONS]"
    echo -e "Options:"
    echo -e "    -x\tPrint full result"
    echo -e "    -a\tComma separated attribute names"
    echo -e "    \tDefault values are $ATTRIBUTES"
    echo -e "    -s\tTicket status"
    echo -e "    \tDefault value is $STATUS_NAME"
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
    if [ "$1" == "-s" ]; then
        shift
        STATUS_NAME=$1
        shift
        continue
    fi
    echo "Wrong arguments." >&2
    exit 1
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

if [ -z "$FULL_RESULT" ]; then
    TICKETS=$(echo -e "$TICKETS\n" | sed "s/<in/\n<in/g" | grep -vs "<?xml")
    if [ -z "$TICKETS" ]; then
        echo "No tickets found."
        exit
    fi

    IFS=$'\n'
    echo -e "OPENED IN \t\t STATUS \t PRIORITY \t SUMMARY"
    for TICKET in $TICKETS; do
        PRIORITY=$(echo $TICKET | sed "s/.*<priority.*COMMON_NAME=\"\([^\"]\+\).*<\/priority.*/\1/g")
        STATUS=$(echo $TICKET | sed "s/.*<status.*COMMON_NAME=\"\([^\"]\+\).*<\/status.*/\1/g")
        SUMMARY=$(echo $TICKET | sed "s/.*<summary>\([^<]\+\).*/\1/g")
        OPEN_DATE=$(echo $TICKET | sed "s/.*<open_date>\([^<]\+\).*/\1/g")
        OPEN_DATE=$(date --date="@$OPEN_DATE" "+%a %d/%m/%Y %H:%M")
        echo -e "$OPEN_DATE \t $STATUS \t $PRIORITY \t $SUMMARY"
    done
    unset IFS
else
    echo $TICKETS | tidy -xml -qi --wrap 0
fi
