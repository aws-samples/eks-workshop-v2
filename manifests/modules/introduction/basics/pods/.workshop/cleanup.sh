#!/bin/bash

set -e

kubectl delete pod ui-pod -n ui --ignore-not-found=true