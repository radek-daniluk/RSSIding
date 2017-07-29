#!/bin/sh

device=/dev/ttyACM1		# default modem tty device character file
userhost=root@192.168.1.1	# default ssh user@host
prefix='RSSIding: '		# prefix for rssi debug messages
delay=1				# AT commands loop delay
dev_delay=2			# wait for device loop delay
info_msg="RSSIding by Radek Daniluk\n
Usage: rssiding [ [user@host] device]
  user@host: ssh connection argument, default: '$userhost'
  device   : path to character device file for modem communication,
  e.g. '/dev/ttyUSB1', default: '$device'\n"


if [ $# -gt 2 ]; then
  printf "$info_msg"
  exit 1
fi

if [ $# -gt 1 ]; then
  device="$2"
  userhost="$1"
elif [ $# -eq 1 ]; then
  device="$1"
fi

printf "%smodem tty device set to: '%s'\n%suser@host set to: '%s'\n" \
"$prefix" "$device" "$prefix" "$userhost"

ssh "$userhost" -T << EOF
printf "%sConnected to '%s'\n" "$prefix" "$userhost"

while true; do
  if [ -c $device ]; then	# if device appeard
    printf "\n%sDevice '%s' found. Proceeding.\n" "$prefix" "$device"
    # TODO lock device 
    chat -e -t 5 ABORT ERROR '' AT+CREG=2 OK \
       <$device 2>&1 1>$device | grep -v ^$ 
    if [ \$? -ne 0 ]; then		 # check chat exit status
      printf "%sChat init problem. Aborting." "$prefix"
      exit 4
    fi
    # TODO unlock device

    while [ -c "$device" ]; do		# device is still there
      date '+%R:%S'
      # TODO lock
      chat -e -t 2 ABORT ERROR '' AT+CSQ OK AT+CREG? OK \
       <$device 2>&1 1>$device | grep -v ^$	 # ask for RSSI and BTS
      #chat info.chat	# send AT commands to obtain RSSI and BTS CID
      # TODO unlock
      # TODO parse and process AT commands
      sleep "$delay"
    done;
  else 		# if there is no device or it disappeard
    printf "%sDevice '%s' not found. Waiting." "$prefix" "$device"
    until [ -c "$device" ]; do 		# still no device
      printf "."
      sleep "$dev_delay"
    done;
  fi
done;

EOF

