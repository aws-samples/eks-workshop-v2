#!/bin/bash

set -e

kubectl delete pod test-pod -n catalog --ignore-not-found=true