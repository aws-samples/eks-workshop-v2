#!/bin/bash

set -e

kubectl delete pod catalog-pod -n catalog --ignore-not-found=true
kubectl delete secret catalog-db -n catalog --ignore-not-found=true