#!/usr/bin/env bash
set -e

if [ $# -ne 2 ]; then
  echo "Usage: ./run_host <network name> <router container>" 2>&1
  exit 1
fi

NETWORK_NAME=$1

if ! ROUTER_CONT_ID=$(docker container inspect -f '{{ .Id }}' $2); then
  echo "Specify a valid container id/name" 2>&1
  exit 2
fi

if ! router_ip=$(docker network inspect -f "{{ (index .Containers \"$ROUTER_CONT_ID\").IPv4Address}}" $NETWORK_NAME); then
  echo "Specify a valid network name" 2>&1
  exit 2
fi


DOCKERFILE_DIR=host
IMAGE_NAME=netsim_host

# Build the image if not exist
if ! docker image inspect -f '{{ .Id }}' $IMAGE_NAME >/dev/null 2>&1; then
  docker build -f $DOCKERFILE_DIR/Dockerfile -t $IMAGE_NAME $DOCKERFILE_DIR
  echo
fi

smart_sleep='echo Container started; trap "exit 0" 15; while sleep 1 & wait $!; do :; done'

cont_id=$(docker run --rm --cap-add=NET_ADMIN --network=$NETWORK_NAME -e ROUTER_IP=$router_ip -d $IMAGE_NAME /bin/sh -c "$smart_sleep")
ip_addr=$(docker container inspect -f "{{.NetworkSettings.Networks.${NETWORK_NAME}.IPAddress}}" $cont_id)

echo 'Container ID'
echo -e "\t$cont_id"
echo 'IP Address'
echo -e "\t$ip_addr"

# docker exec -it $cont_id /bin/bash

