#!/bin/bash

set -e

export VERSION="4.101.2"

curl -fL https://github.com/coder/code-server/releases/download/v$VERSION/code-server-$VERSION-linux-amd64.tar.gz \
  | tar -C /usr/local -xz
mv /usr/local/code-server-$VERSION-linux-amd64 /usr/local/code-server-$VERSION
ln -s /usr/local/code-server-$VERSION/bin/code-server /usr/local/bin/code-server