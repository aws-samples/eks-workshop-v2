#!/bin/bash

set -e

if [ $(readlink -f /dev/xvda) = "/dev/xvda" ]
then
  sudo growpart /dev/xvda 1
  STR=$(cat /etc/os-release)
  SUB="VERSION_ID=\"2\""
  if [[ "$STR" == *"$SUB"* ]]
  then
    sudo xfs_growfs -d /
  else
    sudo resize2fs /dev/xvda1
  fi
else
  sudo growpart /dev/nvme0n1 1
  STR=$(cat /etc/os-release)
  SUB="VERSION_ID=\"2\""
  if [[ "$STR" == *"$SUB"* ]]
  then
    sudo xfs_growfs -d /
  else
    sudo resize2fs /dev/nvme0n1p1
  fi
fi

sudo yum install -y tar gzip openssl jq git gettext bash-completion findutils unzip