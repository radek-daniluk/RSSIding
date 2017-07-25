#!/bin/sh

device=/dev/ttyACM2
echo device="$device"

ssh root@192.168.1.1 -T << EOF
echo ssh->device set to:"$device"

if [ -c "$device" ]; then
  printf "Znaleziono %s. Kontunuuje:\n" "$device";
else
  printf "Nie znaleziono %s. Koncze dzialanie!\n" "$device";
fi

EOF

