#!/bin/bash

set -e

STR=$(cat /etc/os-release)
SUB="VERSION_ID=\"2\""

marker_file="/root/resized.mark"

if [[ ! -f "$marker_file" ]]; then
  if [ $(readlink -f /dev/xvda) = "/dev/xvda" ]
  then
    sudo growpart /dev/xvda 1
    if [[ "$STR" == *"$SUB"* ]]
    then
      sudo xfs_growfs -d /
    else
      sudo resize2fs /dev/xvda1
    fi
  else
    sudo growpart /dev/nvme0n1 1
    if [[ "$STR" == *"$SUB"* ]]
    then
      sudo xfs_growfs -d /
    else
      sudo resize2fs /dev/nvme0n1p1
    fi
  fi
fi

touch $marker_file

sudo yum install -y git
