#!/bin/bash

set -e

echo "Uninstalling flux"

flux uninstall --silent > /dev/null

kubectl delete namespace ui > /dev/null

rm -rf ~/environment/flux