#!/bin/sh

device=/dev/ttyACM1		# default modem character device file
userhost=root@192.168.1.1	# default ssh user@host
prefix='RSSIding: '		# prefix for rssi debug messages
dev_timeout=29			# timeout if modem char dev file not exist
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
printf "%sConnected to '%s'\n" "$prefix" "$userhost"
printf "%sWaiting for '%s'.." "$prefix" "$device"

i=0		# variable declaration inside here document!
until [ -c "$device" ];
do

  i=\$(( \$i + 1 )) # modify i variable inside here document
  if [ "\$i" -gt "$dev_timeout" ]; then
    printf "\n%sDevice '%s' not found for %s seconds. Exiting.\n" \
      "$prefix" "$device" "$dev_timeout"
    exit 2
  fi
  printf "."; sleep 1;
done;


printf "\n%sDevice '%s' found. Proceeding.\n" "$prefix" "$device"

EOF

