#!/bin/bash

set -e

curl -fsSL https://github.com/vmware-tanzu/carvel-vendir/releases/download/v0.26.0/vendir-linux-amd64 -o vendir
echo "98057bf90e09972f156d1c4fbde350e94133bbaf2e25818b007759f5e9c8b197  vendir" | sha256sum --check
chmod +x vendir && mv vendir /usr/bin/vendir

mkdir -p /usr/local/tools-bin

vendir sync --locked

mkdir -p /usr/local/tools-bin/staging

find vendor -mindepth 2 -type f -exec mv -t /usr/local/tools-bin/staging -i '{}' +

chmod +x /usr/local/tools-bin/staging/*

cp -R /usr/local/tools-bin/staging/* /usr/local/tools-bin

rm -rf /usr/local/tools-bin/staging vendor

echo 'export PATH=$PATH:/usr/local/tools-bin' >> /etc/profile