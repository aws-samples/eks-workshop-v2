#!/bin/bash

set -e

logmessage "Deleting EFS storage class..."

kubectl delete storageclass efs-sc --ignore-not-found
