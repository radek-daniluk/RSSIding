#!/bin/sh

user='root'
host='192.168.1.1'
remote="$user@$host"
dir=/tmp/
file=rssi.sh

set -e  # exit immediately if a command exits with a non-zero status
#set -x	# print commands

scp $file $remote:$dir
ssh $remote 'chmod u+x '$dir$file

while : ; do
ssh $remote "$dir./$file /dev/ttyACM1 0" | awk -F"[= ]" '/^([0-9]{2}:){2}[0-9]{2} RSSI/ { print $0; system("play -n synth 0.5 sin %$3-10 2>/dev/null") }'
done;


