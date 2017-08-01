#!/bin/sh

user='root'
host='192.168.1.1'
remote="$user@$host"
dir=/tmp/
file=rssi.sh

set -e  # exit immediately if a command exits with a non-zero status
set -x	# print commands

scp $file $remote:$dir
ssh $remote 'chmod u+x '$dir$file
