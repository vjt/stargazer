#!/bin/bash
#
# Script parameters:
# 1: shutter opening delay
# 2: exposure time in seconds
# 3: amount of shots
# 4: delay between shots
#

for i in `seq $3`; do
{
  ./set-serial-signal /dev/ttyUSB0 0 0 &&
  sleep $1 && ./set-serial-signal /dev/ttyUSB0 0 1 &&
  sleep 0.3 && ./set-serial-signal /dev/ttyUSB0 0 0 &&
  sleep $2 && ./set-serial-signal /dev/ttyUSB0 1 1 &&
  echo "One more image captured!" &&
  sleep $4;

}
done

echo "Done!"
