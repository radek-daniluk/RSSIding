#!/bin/sh

device=/dev/ttyACM1             # default modem tty device character file
delay=1                         # AT commands loop delay
dev_delay=2                     # wait for device loop delay
lock_dir=/tmp/rssi.lock		# lock directory (one instance of script)
tmp_file=/tmp/rssi.tmp		# temporary file for AT commands

info_msg="rssi by Radek Daniluk\n
Usage: rssi [device [delay]]
  device	: path to character device file for modem communication,
    e.g. '/dev/ttyUSB1', default: '$device'
  delay		: AT commands loop delay in seconds; default: '$delay'\n"

if [ $# -gt 2 ]; then		# too many args
  printf "$info_msg"
  exit 1
fi

if [ $# -gt 1 ]; then
  device="$1"
  delay="$2"
elif [ $# -eq 1 ]; then
  device="$1"
fi

printf "modem tty device set to: '%s'\nLoop delay set to: '%s'\n" \
"$device" "$delay"

# set exclusive lock
if true; then # TODO

  echo >&2 "successfully acquired lock"
  # Remove lockdir when the script finishes, or when it receives a signal
  trap 'rm -rf "$lockdir"' 0    # remove directory when script finishes

  while true; do
    if [ -c $device ]; then       # if device appeard
      printf "\nDevice '%s' found. Proceeding.\n" "$device"

      # send initial AT commands to modem device
      chat -e -t 5 ABORT ERROR '' AT+CREG=2 OK <$device 2>&1 1>$device \
        | grep -v ^$			# remove empty lines
      if [ $? -ne 0 ]; then               # check chat exit status
        printf "Chat init error. Aborting.\n"
        exit 4
      fi

      while [ -c "$device" ]; do          # device is still there
        date '+%R:%S'     # print time
        # send AT commands asking for RSSI and registration status
        # and save answer to temp file
        chat -e -t 2 ABORT ERROR '' AT+CSQ OK AT+CREG? OK \
          <$device 2>$tmp_file 1>$device
        if [ $? -ne 0 ]; then		# check chat exit status
          echo chat error > $tmp_file
        fi

        #parse AT commands and remove empty lines from temporary file
        sed -i -E '/^$/ d' $tmp_file
        cat $tmp_file
        #RSSI=$(awk -F "[ ,]" '/^\+CSQ:/ { print $2 }' $tmp_file)
        sleep "$delay"
      done;
    else          # if there is no device or it disappeard
      printf "Device '%s' not found. Waiting." "$device"
      until [ -c "$device" ]; do          # still no device
        printf '.'
        sleep "$dev_delay"
      done;
    fi
  done;

else # unable to lock
     echo >&2 "cannot acquire lock, giving up on $lock_dir"
     exit 0
fi
