#!/bin/bash

echo "Uninstalling flux"

flux uninstall --silent > /dev/null

kubectl delete namespace ui > /dev/null