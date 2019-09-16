#!/bin/bash

set -e

SDM_CLI_DIR=$( dirname $(realpath $0) )

MAX_RESULTS=10
ATTRIBUTES="status, priority, summary, open_date"
OUTPUT_MODE="TABLE"

if [ -z "$1" ]; then
    echo "Usage: sdm-tickets.sh [OPTIONS]"
    echo -e "Options:"
    echo -e "    -a, --attr-list <LIST>\tComma separated attribute names (only works with -x option)"
    echo -e "    \t\t\t\tDefault values are $ATTRIBUTES"
    echo -e "    -g, --group <GROUP>\t\tGroup name"
    echo -e "    -l <LENGTH>\t\t\tMax result length"
    echo -e "    \t\t\t\tDefault value is $MAX_RESULTS"
    echo -e "    -n\t\t\t\tPrint ticket numbers only"
    echo -e "    -s, --status <STATUS>\tTicket status name"
    echo -e "    \t\t\t\tIf not defined, all active tickets will be returned"
    echo -e "    -x, --xml\t\t\tPrint XML result"
    exit 1
fi

while [ -n "$1" ]; do
    if [ "$1" == "-n" ]; then
        OUTPUT_MODE="NUMBER"
        shift
        continue
    fi
    if [ "$1" == "-x" ] || [ "$1" == "--xml" ]; then
        OUTPUT_MODE="XML"
        shift
        continue
    fi
    if [ "$1" == "-g" ] || [ "$1" == "--group" ]; then
        shift
        GROUP_NAME=$1
        shift
        continue
    fi
    if [ "$1" == "-a" ] || [ "$1" == "--attr-list" ]; then
        shift
        ATTRIBUTES=$(echo $1 | sed s/^all$/\*/g)
        shift
        continue
    fi
    if [ "$1" == "-s" ] || [ "$1" == "--status" ]; then
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

if [ -n "$STATUS_NAME" ]; then
    STATUS_ID=$($SDM_CLI_DIR/sdm-status.sh "$STATUS_NAME")
    QUERY="status='$STATUS_ID'"
else
    QUERY="active=1"
fi

if [ -n "$GROUP_NAME" ]; then
    GROUP_ID=$($SDM_CLI_DIR/sdm-group.sh "$GROUP_NAME")
    QUERY="$QUERY and group='$GROUP_ID'"
fi

QUERY=$(echo $QUERY | sed "s/ /%20/g" | sed "s/=/%3D/g")

TICKETS=$(curl -s \
    -H "X-AccessKey: $ACCESS_KEY" \
    -H "X-Obj-Attrs: $ATTRIBUTES" \
    "$SDM_HOST/caisd-rest/cr?start=1&size=$MAX_RESULTS&WC=$QUERY")

if [ "$OUTPUT_MODE" == "TABLE" ]; then
    TICKETS=$(echo -e "$TICKETS\n" | sed "s/<cr/\n<cr/g" | grep -vs "<?xml")
    if [ -z "$TICKETS" ]; then
        echo "No tickets found."
        exit
    fi

    IFS=$'\n'
    printf "%-13s %-20s %-20s %-10s \t %s\n" "ID" "OPENED IN" "STATUS" "PRIORITY" "SUMMARY"
    for TICKET in $TICKETS; do
        TICKET_NUMBER=$(echo $TICKET | sed -r "s/<cr[^>]+COMMON_NAME=\"([^\"]+).*/\1/g")
        PRIORITY=$(echo $TICKET | sed -r "s/.*<priority[^>]+COMMON_NAME=\"([^\"]+).*/\1/g")
        STATUS=$(echo $TICKET | sed -r "s/.*<status[^>]+COMMON_NAME=\"([^\"]+).*/\1/g")
        SUMMARY=$(echo $TICKET | sed -r "s/.*<summary>([^<]+).*/\1/g")
        OPEN_DATE=$(echo $TICKET | sed -r "s/.*<open_date>([^<]+).*/\1/g")
        OPEN_DATE=$(date --date="@$OPEN_DATE" "+%d/%m/%Y %H:%M")
        printf "%-13s %-20s %-20s %-10s \t %s\n" "$TICKET_NUMBER" "$OPEN_DATE" "$STATUS" "$PRIORITY" "$SUMMARY"
    done
    unset IFS
elif [ "$OUTPUT_MODE" == "NUMBER" ]; then
    echo -e "$TICKETS" | sed -r "s/<cr/\r\n<cr/g" | grep -vs "<?xml" | sed -r "s/<cr[^>]*COMMON_NAME=\"([^\"]*).*/\1/g"
else
    echo $TICKETS | tidy -xml -qi --wrap 0
fi
