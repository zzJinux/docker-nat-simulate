#!/usr/bin/env bash
set -e

if [ $# -ne 2 ]; then
  echo "Usage: ./add_route <container id> <network name>" 2>&1
  exit 1
fi

cont_id=$1

subnet=$(docker network inspect -f '{{ (index .IPAM.Config 0).Subnet }}' $2)
router_ip=$(docker exec $cont_id /bin/bash -c 'echo $ROUTER_IP')

docker exec $cont_id ip route add $subnet via ${router_ip%/*} dev eth0
