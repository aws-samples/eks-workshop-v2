#!/bin/bash

echo "Deleting RDS resources created by ACK..."

kubectl delete namespace catalog > /dev/null