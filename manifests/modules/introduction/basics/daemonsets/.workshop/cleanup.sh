#!/bin/bash

set -e

kubectl delete daemonset log-collector -n kube-system --ignore-not-found=true
