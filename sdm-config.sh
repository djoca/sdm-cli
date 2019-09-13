#!/bin/bash

CONFIG_DIR=~/.sdm-cli
CONFIG_FILE=$CONFIG_DIR/sdm-cli.conf

if (( $# < 1 )); then
    echo "Usage: sdm-config.sh -h"
    echo "Options:"
    echo -e "    -h\tSDM host"
    exit 1
fi

if [ ! -f $CONFIG_FILE ]; then
    echo "Config file not found at $SDM_CLI_DIR" >&2
    exit 1
fi

PARAM_KEY="sdm-host"

PARAM_VALUE=$(cat $CONFIG_FILE | grep $PARAM_KEY | cut -d":" -f2-)

if [ -z "$PARAM_VALUE" ]; then
    echo "parameter $PARAM_KEY not found." >&2
    exit 1
fi

echo $PARAM_VALUE
