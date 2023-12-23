#!/bin/bash

set -e

logmessage "Uninstalling flux"

flux uninstall --silent

kubectl delete namespace ui

rm -rf ~/environment/flux