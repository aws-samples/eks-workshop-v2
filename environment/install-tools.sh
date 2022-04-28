#!/bin/bash

set -e

curl -fsSL https://github.com/vmware-tanzu/carvel-vendir/releases/download/v0.27.0/vendir-linux-amd64 -o vendir
echo "1aa12d070f2e91fcb0f4d138704c5061075b0821e6f943f5a39676d7a4709142  vendir" | sha256sum --check
chmod +x vendir && mv vendir /usr/bin/vendir

mkdir -p /usr/local/tools-bin

vendir sync --locked

mkdir -p /usr/local/tools-bin/staging

find vendor -mindepth 2 -type f -exec mv -t /usr/local/tools-bin/staging -i '{}' +

chmod +x /usr/local/tools-bin/staging/*

cp -R /usr/local/tools-bin/staging/* /usr/local/tools-bin

rm -rf /usr/local/tools-bin/staging vendor

echo 'export PATH=$PATH:/usr/local/tools-bin' >> /etc/profile