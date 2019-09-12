#!/bin/bash

set -e

MAX_RESULTS=10
ATTRIBUTES="status, priority, summary, open_date"
STATUS_NAME=Aberto

if [ -z "$1" ]; then
    echo "Usage: sdm-tickets.sh <GROUP_NAME> [OPTIONS]"
    echo -e "Options:"
    echo -e "    -x\tPrint full result"
    echo -e "    -a\tComma separated attribute names"
    echo -e "    \tDefault values are $ATTRIBUTES"
    echo -e "    -s\tTicket status"
    echo -e "    \tDefault value is $STATUS_NAME"
    exit 1
fi

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

ACCESS_KEY=$(./sdm-authenticate.sh -r)

GROUP_ID=$(./sdm-group.sh "$GROUP_NAME")

if [ -n "$STATUS_NAME" ]; then
    STATUS_ID=$(./sdm-status.sh "$STATUS_NAME")
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
    printf "%-13s %-20s %-20s %-10s \t %s\n" "ID" "OPENED IN" "STATUS" "PRIORITY" "SUMMARY"
    for TICKET in $TICKETS; do
        TICKET_NUMBER=$(echo $TICKET | sed -r "s/<in[^>]+COMMON_NAME=\"([^\"]+).*/\1/g")
        PRIORITY=$(echo $TICKET | sed -r "s/.*<priority[^>]+COMMON_NAME=\"([^\"]+).*/\1/g")
        STATUS=$(echo $TICKET | sed -r "s/.*<status[^>]+COMMON_NAME=\"([^\"]+).*/\1/g")
        SUMMARY=$(echo $TICKET | sed -r "s/.*<summary>([^<]+).*/\1/g")
        OPEN_DATE=$(echo $TICKET | sed -r "s/.*<open_date>([^<]+).*/\1/g")
        OPEN_DATE=$(date --date="@$OPEN_DATE" "+%d/%m/%Y %H:%M")
        printf "%-13s %-20s %-20s %-10s \t %s\n" "$TICKET_NUMBER" "$OPEN_DATE" "$STATUS" "$PRIORITY" "$SUMMARY"
    done
    unset IFS
else
    echo $TICKETS | tidy -xml -qi --wrap 0
fi
