#!/bin/bash

set -e

kubectl delete namespace ui --ignore-not-found
kubectl delete namespace catalog --ignore-not-found