#!/bin/bash

# Run as root?
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root!"
  exit 1
fi

# header
echo -e "COMMAND\tPID\tUSER\tSIZE\tNODE\tNAME"

# PID:
find /proc -maxdepth 1 -type d | cut -f3 -d '/' | grep -E [0-9]+ | sort -n | grep -v $$ | while read pid; do
  # COMMAND, USER:
  if [[ -f /proc/$pid/comm ]]; then
    command=$(cat /proc/$pid/comm)
    user=$(ls -ld /proc/$pid | awk '{print $3}')
  else 
    command=' '
    user=' '
  fi

  # cwd, SIZE, NODE:
  if [[ -e /proc/$pid/cwd ]]; then
    file=$(readlink -f /proc/$pid/cwd)
    size=$(stat $file 2> /dev/null | grep 'Size:' | awk '{print $2}')
    node=$(stat $file 2> /dev/null | grep 'Inode:' | awk '{print $4}')
    echo -e "$command\t$pid\t$user\t$size\t$node\t$file"
  fi

  # list files in maps
  if [[ -f /proc/$pid/maps ]]; then
    awk '$NF ~ "^/" {print $NF}' /proc/$pid/maps | sort -r | uniq | while read file; do
      size=$(stat $file 2> /dev/null | grep 'Size:' | awk '{print $2}')
      node=$(stat $file 2> /dev/null | grep 'Inode:' | awk '{print $4}')
      echo -e "$command\t$pid\t$user\t$size\t$node\t$file"
    done
  fi

  # list files in fd
  if [[ -d /proc/$pid/fd ]]; then
    ls /proc/$pid/fd/ | while read fd; do
      file=$(readlink -f /proc/$pid/fd/$fd)
      size=$(stat $file 2> /dev/null | grep 'Size:' | awk '{print $2}')
      node=$(stat $file 2> /dev/null | grep 'Inode:' | awk '{print $4}')
      echo -e "$command\t$pid\t$user\t$size\t$node\t$file"
    done
  fi
done

