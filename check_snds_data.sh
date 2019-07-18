#!/bin/bash

#####
#
# Monitoring plugin to check, if the 'colour' state of an IP address in SNDS.
#
# Forked from check_snds by Jan Vonde.
#
# Copyright (c) 2017 Jan Vonde <mail@jan-von.de>
# Copyright (c) 2019 Kienan Stewart <kienan@koumbit.org>
#
# Usage: ./check_snds.sh -i 1.2.3.4 -k aaa-bbb-ccc-111-222-333
#
#
# For more information visit https://github.com/janvonde/check_snds
#
#####


USAGE="Usage: check_snds.sh -i [IP] -k [KEY]"

if [ $# -ge 4 ]; then
    while getopts "i:k:"  OPCOES; do
        case $OPCOES in
            i ) IP=$OPTARG;;
            k ) KEY=$OPTARG;;
            * ) echo "$USAGE"
                 exit 1;;
        esac
    done
else 
    echo "$USAGE"; exit 3
fi


## check if needed programs are installed
type -P curl &>/dev/null || { echo "ERROR: curl is required but seems not to be installed.  Aborting." >&2; exit 1; }
type -P sed &>/dev/null || { echo "ERROR: sed is required but seems not to be installed.  Aborting." >&2; exit 1; }


## get ipStatus from SNDS
SNDSFILE=$(curl -s https://sendersupport.olc.protection.outlook.com/snds/data.aspx?key="${KEY}" | grep "$IP")


## check if IP is included in SNDSFILE
if [[ ! -z "$SNDSFILE" ]]; then
    COLOUR=$(echo "$SNDSFILE" | cut -d ',' -f 7)
    COMPLAINT_RATE=$(echo "$SNDSFILE" | cut -d ',' -f 8)
    PERIOD=$(echo "$SNDSFILE" | cut -d ',' -f 2,3)
    STATS=$(echo "$SNDSFILE" | cut -d ',' -f 4,5,6)
    case "$COLOUR" in
        "GREEN")
            echo "OK: IP ${IP} is ${COLOUR} IN PERIOD ${PERIOD} (${COMPLAINT_RATE},${STATS})"
        ;;
        "YELLOW")
            echo "WARNING: IP ${IP} is ${COLOUR} IN PERIOD ${PERIOD} (${COMPLAINT_RATE},${STATS})"
            exit 1
        ;;
        "RED")
            echo "ERROR: IP ${IP} is ${COLOUR} IN PERIOD ${PERIOD} (${COMPLAINT_RATE},${STATS})"
            exit 2
            ;;
        "*")
            echo "WARNING: UNKNOWN RESULT ${COLOUR} FOR IP ${IP}"
            exit 1
    esac
else
    echo "WARNING: IP ${IP} is not listed in SNDS data"
    exit 1
fi
