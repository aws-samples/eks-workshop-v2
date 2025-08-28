#!/bin/bash

set -e

uninstall-helm-chart ui ui

kubectl delete namespace ui --ignore-not-found