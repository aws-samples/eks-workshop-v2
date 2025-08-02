#!/bin/bash

set -e

kubectl delete namespace pss --ignore-not-found=true
