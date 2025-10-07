#!/bin/bash

set -e

kubectl delete pod test-pod --ignore-not-found=true