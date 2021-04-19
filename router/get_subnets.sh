#!/usr/bin/env bash

# Intended to be run on Docker host

# Print information of subnets bound to the container
set -eu

if [ $# -lt 2 ]; then
  echo "Usage: ./get_subnets.sh <container id> [ <network name> ... ]" 2>&1 1>/dev/null
  exit 2
fi

CONT_ID=$1; shift

for subnet_name in "$@"; do
  ip_addr=$(docker container inspect -f "{{.NetworkSettings.Networks.$subnet_name.IPAddress}}" $CONT_ID)
  mac_addr=$(docker container inspect -f "{{.NetworkSettings.Networks.$subnet_name.MacAddress}}" $CONT_ID)
  echo $ip_addr $mac_addr
done
