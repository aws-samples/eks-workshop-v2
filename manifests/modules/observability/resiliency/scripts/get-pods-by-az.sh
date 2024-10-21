#!/bin/bash

# Modified from "Disaster recovery, high availability, and resiliency on Amazon EKS"
# https://catalog.us-east-1.prod.workshops.aws/workshops/6140457f-53b2-48b8-a007-2d4be06ba2fc

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

CURRENT_CONTEXT=$(kubectl config current-context)
REGION=$(kubectl config view -o jsonpath="{.contexts[?(@.name == \"$CURRENT_CONTEXT\")].context.cluster}" | cut -d : -f 4)

# Function to clear the screen and move cursor to top-left
clear_screen() {
    echo -e "\033[2J\033[H"
}

# Function to generate the output
generate_output() {
    echo -e '\n\n\n'
    for az in a b c
    do
        AZ=$REGION$az
        echo -n "------"
        echo -n -e "${GREEN}$AZ${NC}"
        echo "------"
        for node in $(kubectl get nodes -l topology.kubernetes.io/zone=$AZ --no-headers | grep -v NotReady | cut -d " " -f1)
        do
            echo -e "  ${RED}$node:${NC}"
            kubectl get pods -n ui --no-headers --field-selector spec.nodeName=${node} 2>&1 | while read line; do echo "       ${line}"; done
        done
        echo ""
    done
    echo -e '\n\n\n'
}

# Initial clear screen
# clear_screen

trap 'rm -rf ~/environment/eks-workshop/temp_output.txt; exit 0' SIGTERM INT
# Main loop
while true; do

    # Generate output to a temporary file
    generate_output > ~/environment/eks-workshop/temp_output.txt

    #generate_output
    # Clear screen and display the new output
    # clear_screen
    cat ~/environment/eks-workshop/temp_output.txt
    # clear_screen

    # Wait before next update
    sleep 1
done
