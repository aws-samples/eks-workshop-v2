#!/bin/bash

logmessage "Deleting resources created by ACK..."

delete-all-if-crd-exists tables.dynamodb.services.k8s.aws

uninstall-helm-chart ack-dynamodb ack-system