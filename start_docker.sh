#!/bin/bash

#
# start_docker.sh -- a shell wrapper for the HorusRPiTX utility
# Andrew Koenig KE5GDB, 2025
#

# Defaults
: "${FREQ:=434.200}"
: "${ID:=256}"
: "${LAT:=0}"
: "${LON:=0}"
: "${ALT:=0}"
: "${SATS:=3}"
: "${DEVICE:=/dev/ttyUSB0}"

cd /root/horusrpitx/

# Check that an operating mode has been set.
if [ -z "$MODE" ]; then
	echo "ERROR: MODE has not been set."
	exit 1
fi

if [ "$VERBOSE" == "1" ] ; then
	VERBOSE="--verbose"
fi

# If MODE was defined as TEST, send sample packets
if [ "$MODE" == "TEST" ] ; then
	echo "Starting PacketTX.py"
	python3 /root/horusrpitx/PacketTX.py --frequency $FREQ --id $ID --lat $LAT --lon $LON --alt $ALT --sats $SATS $VERBOSE
#If MODE was defined as GPS, send GPS data
elif [ "$MODE" == "GPS" ] ; then
	echo "Starting tx_gps.py"
	python3 /root/horusrpitx/tx_gps.py $ID --docker --frequency $FREQ --gps $DEVICE $VERBOSE
else
	echo "Invalid mode specified! Exiting..."
	exit 1
fi
