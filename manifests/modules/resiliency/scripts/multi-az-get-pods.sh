#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

REGIONS=("us-west-2" "us-east-2")

for REGION in "${REGIONS[@]}"
do
  echo "Region: $REGION"
  for az in a b c
  do
    AZ=$REGION$az
    echo -n "------"
    echo -n -e "${GREEN}$AZ${NC}"
    echo "------"
    for node in $(kubectl get nodes -l topology.kubernetes.io/zone=$AZ --no-headers 2>/dev/null | grep -v NotReady | cut -d " " -f1)
    do
      echo -e "  ${RED}$node:${NC}"
      kubectl get pods -n ui --no-headers --field-selector spec.nodeName=${node} 2>/dev/null | while read line; do echo "       ${line}"; done
    done
    echo ""
  done
  echo ""
done