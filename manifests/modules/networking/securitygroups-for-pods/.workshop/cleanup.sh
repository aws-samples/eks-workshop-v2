#!/bin/bash

set -e

logmessage "Deleting Security Group policies..."

kubectl delete SecurityGroupPolicy --all -A

sleep 30

kubectl delete namespace catalog