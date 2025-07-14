#!/bin/bash

set -e

export VERSION="4.101.2"
arch=$(uname -m)
arch_name=""

# Convert to amd64 or arm64
case "$arch" in
  x86_64)
    arch_name="amd64"
    ;;
  aarch64)
    arch_name="arm64"
    ;;
  *)
    echo "Unsupported architecture: $arch"
    exit 1
    ;;
esac


curl -fL https://github.com/coder/code-server/releases/download/v$VERSION/code-server-$VERSION-linux-${arch_name}.tar.gz \
  | tar -C /usr/local -xz
mv /usr/local/code-server-$VERSION-linux-${arch_name} /usr/local/code-server-$VERSION
ln -s /usr/local/code-server-$VERSION/bin/code-server /usr/local/bin/code-server