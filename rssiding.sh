#!/bin/sh

device=/dev/ttyACM1
userhost=root@192.168.1.1
prefix='rssiding->'
usage="RSSIding by Radek Daniluk\n
Usage: rssiding [ [user@host] device]
  user@host: ssh connection argument, default: '$userhost'
  device   : path to character device file for modem communication,
  e.g. '/dev/ttyUSB1', default: '$device'\n"


if [ $# -gt 2 ]; then
  printf "$usage"
  exit 1
fi

if [ $# -gt 1 ]; then
  device="$2"
  userhost="$1"
elif [ $# -eq 1 ]; then
  device="$1"
fi

printf "%smodem character device set to: '%s'\n%suser@host set to: '%s'\n" \
"$prefix" "$device" "$prefix" "$userhost"

ssh "$userhost" -T << EOF
printf "%sconnected to '%s'\n" "$prefix" "$userhost"

if [ -c "$device" ]; then
  printf "Znaleziono '%s'. Kontunuuje:\n" "$device";
else
  printf "Nie znaleziono '%s'. Koncze dzialanie!\n" "$device";
fi

EOF

