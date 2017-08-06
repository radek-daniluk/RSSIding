#!/bin/sh

device=/dev/ttyACM1             # default modem tty device character file
delay=1                         # AT commands loop delay
dev_delay=2                     # wait for device loop delay
lock_dir=/tmp/rssi.lock		# lock directory (one instance of script)
tmp_file=/tmp/rssi.tmp		# temporary file for AT commands
print_full_chat=0

info_msg="rssi by Radek Daniluk\n
Usage: rssi [device [delay [full_chat]]]
  device	: path to character device file for modem communication,
		  must start from '/dev/tty'
		  e.g. '/dev/ttyUSB1', default: '$device'
  delay		: AT commands loop delay in seconds; default: '$delay'
		  maximum delay time: '99'
		  if set to 0 script prints info once and exits
  full_chat	: if set to 0 print pretty info, otherwise print full modem
		  chat, default: $print_full_chat\n"

if [ $# -gt 3 ]; then		# too many args
  printf "$info_msg"
  exit 1
fi

# 'case' unlike 'if test' do not execute backtick commands passed by arguments
# (set argument to "`ls`" and you will see difference)
# for safety reasons using case

if [ $# -gt 2 ]; then 		# prcoess 3rd argument
  case $3 in
  1) print_full_chat=1;;
  *) print_full_chat=0;;
  esac
fi

if [ $# -gt 1 ]; then		# process 2nd argument
  case $2 in
    [0-9]|[0-9][0-9])		# number 0-99
      delay="$2" ;;
    *)
      echo Bad delay argument format
      printf "$info_msg"
      exit 1 ;;
  esac
fi

if [ $# -gt 0 ]; then		# process 1st argument
  case $1 in
    /dev/tty?*)
      device="$1";;
    *)
      echo Bad device argument format
      printf "$info_msg"
      exit 1 ;;
  esac
fi

printf "modem tty device set to: '%s'
Loop delay set to: %ss
print_full_chat: '%s'\n" \
"$device" "$delay" "$print_full_chat"

# set exclusive lock
if : ; then # TODO

  echo >&2 "successfully acquired lock"
  # Remove lockdir when the script finishes, or when it receives a signal
  trap 'rm -rf "$lockdir"' 0    # remove directory when script finishes

  while : ; do
    if [ -c $device ]; then       # if device appeard
      printf "\nDevice '%s' found. Proceeding.\n" "$device"

      # send initial AT commands to modem device
      chat -e -t 5 ABORT ERROR '' AT+CREG=2 OK <$device 2>$tmp_file 1>$device
      if [ $? -ne 0 ]; then		# check chat exit status
        printf "Chat init error. Aborting.\n"
        exit 4
      else
        if [ "$print_full_chat" -eq 1 ]; then
          sed -i -E '/^$/ d' $tmp_file	# remove empty lines
          cat "$tmp_file"
        fi
      fi

      while [ -c "$device" ]; do          # device is still there
        # send AT commands asking for RSSI and registration status
        # and save answer to temp file
        chat -e -t 2 ABORT ERROR '' AT+CSQ OK AT+CREG? OK \
          <$device 2>$tmp_file 1>$device
        if [ $? -ne 0 ]; then		# check chat exit status
          echo chat error > $tmp_file
        fi

        # parse AT commands and remove empty lines from temporary file
        sed -i -E '/^$/ d' $tmp_file

        # print result
        if [ "$print_full_chat" -eq 1 ]; then
          date '+%R:%S'
          cat $tmp_file
        else
          date '+%R:%S' | tr -d '\n' # print date without newline
          RSSI=$(awk -F "[ ,]" '/^\+CSQ:/ { print $2 }' $tmp_file)
          BTS_CI=$(awk -F "[ ,]" '/^\+CREG:/ { print $5 }' $tmp_file)
          printf " RSSI=%s BTS_CI=%s\n" "$RSSI" "$BTS_CI"
        fi

        if [ "$delay" -ne 0 ]; then
          sleep "$delay"
        else
          exit 0
        fi
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
