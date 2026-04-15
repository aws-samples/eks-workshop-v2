#!/bin/bash

# Resolves SOURCE_IP_ADDRESS to INBOUND_CIDRS
# If SOURCE_IP_ADDRESS is blank or "auto", resolves the current public IP
# Otherwise uses the provided value verbatim

if [ -z "${SOURCE_IP_ADDRESS:-}" ] || [ "${SOURCE_IP_ADDRESS:-}" = "auto" ]; then
  SOURCE_IP_ADDRESS=$(curl -s https://checkip.amazonaws.com)
  echo "Resolved source IP address: ${SOURCE_IP_ADDRESS}"
else
  echo "Using provided source IP address: ${SOURCE_IP_ADDRESS}"
fi

export INBOUND_CIDRS="${SOURCE_IP_ADDRESS}/32"
echo "Inbound CIDRs: ${INBOUND_CIDRS}"
