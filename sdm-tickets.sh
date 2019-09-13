#!/bin/bash

set -e

SDM_CLI_DIR=$( dirname $(realpath $0) )

MAX_RESULTS=10
ATTRIBUTES="status, priority, summary, open_date"
STATUS_NAME=Aberto
OUTPUT_MODE="TABLE"

if [ -z "$1" ]; then
    echo "Usage: sdm-tickets.sh <GROUP_NAME> [OPTIONS]"
    echo -e "Options:"
    echo -e "    -x\tPrint XML result"
    echo -e "    -n\tPrint ticket numbers only"
    echo -e "    -a\tComma separated attribute names (only works with -x option)"
    echo -e "    \tDefault values are $ATTRIBUTES"
    echo -e "    -s\tTicket status"
    echo -e "    \tDefault value is $STATUS_NAME"
    echo -e "    -l\tMax result length"
    echo -e "    \tDefault value is $MAX_RESULTS"
    exit 1
fi

GROUP_NAME=$1; shift

while [ -n "$1" ]; do
    if [ "$1" == "-n" ]; then
        OUTPUT_MODE="NUMBER"
        shift
        continue
    fi
    if [ "$1" == "-x" ]; then
        OUTPUT_MODE="XML"
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
    if [ "$1" == "-l" ]; then
        shift
        MAX_RESULTS=$1
        shift
        continue
    fi
    echo "Wrong arguments." >&2
    exit 1
done

SDM_HOST=$($SDM_CLI_DIR/sdm-config.sh -g)
ACCESS_KEY=$($SDM_CLI_DIR/sdm-authenticate.sh -r)

GROUP_ID=$($SDM_CLI_DIR/sdm-group.sh "$GROUP_NAME")

if [ -n "$STATUS_NAME" ]; then
    STATUS_ID=$($SDM_CLI_DIR/sdm-status.sh "$STATUS_NAME")
    STATUS_QUERY=" and status='$STATUS_ID'"
    STATUS_QUERY=$(echo $STATUS_QUERY | sed "s/ /%20/g" | sed "s/=/%3D/g")
fi

TICKETS=$(curl -s \
    -H "X-AccessKey: $ACCESS_KEY" \
    -H "X-Obj-Attrs: $ATTRIBUTES" \
    "$SDM_HOST/caisd-rest/in?start=1&size=$MAX_RESULTS&WC=group%3D'$GROUP_ID'$STATUS_QUERY")

if [ "$OUTPUT_MODE" == "TABLE" ]; then
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
elif [ "$OUTPUT_MODE" == "NUMBER" ]; then
    echo -e "$TICKETS" | sed -r "s/<in/\r\n<in/g" | grep -vs "<?xml" | sed -r "s/<in[^>]*COMMON_NAME=\"([^\"]*).*/\1/g"
else
    echo $TICKETS | tidy -xml -qi --wrap 0
fi
