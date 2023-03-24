#!/bin/bash

echo "Deleting Security Group policies..."

kubectl delete SecurityGroupPolicy --all -A > /dev/null
