#!/usr/bin/env bash
set -e

if [ $# -eq 0 ]; then
  echo "Usage: ./run_router <network_name1> [ <network_name2> ... ]" 2>&1
fi

DOCKERFILE_DIR=router
IMAGE_NAME=netsim_router
NAT_SUBNET_NAME=$1; shift
NAT_SUBNET=$(docker network inspect -f '{{(index .IPAM.Config 0).Subnet}}' $NAT_SUBNET_NAME)
IPTABLES_BIN=iptables-legacy

# Build the image if not exist
if ! docker image inspect -f '{{ .Name }}' $IMAGE_NAME >/dev/null 2>&1; then
  docker build -f $DOCKERFILE_DIR/Dockerfile -t $IMAGE_NAME $DOCKERFILE_DIR
  echo
fi

# Create a container
cont_id=$(docker create --rm --network=$NAT_SUBNET_NAME --cap-add=NET_ADMIN $IMAGE_NAME)


# Connect remaining networks
for subnet_name in "$@"; do
  docker network connect $subnet_name $cont_id
done


docker start $cont_id &>/dev/null
ip_addr=$(docker container inspect -f "{{.NetworkSettings.Networks.${NAT_SUBNET_NAME}.IPAddress}}" $cont_id)


echo 'Container ID'
echo -e "\t$cont_id"
echo "IP Address ($NAT_SUBNET_NAME)"
echo -e "\t$ip_addr"

for subnet_name in "$@"; do
  _ip_address=$(docker container inspect -f "{{.NetworkSettings.Networks.$subnet_name.IPAddress}}" $cont_id)

  echo "IP Address ($subnet_name)"
  echo -e "\t$_ip_address"
done


# IP Address that belongs to NATed subnet
echo 'Configuring iptables for SNAT and logging...'
for subnet_name in "$@"; do
  _ip_address=$(docker container inspect -f "{{.NetworkSettings.Networks.$subnet_name.IPAddress}}" $cont_id)
  _mac_address=$(docker container inspect -f "{{.NetworkSettings.Networks.$subnet_name.MacAddress}}" $cont_id)
  _ifname=$(docker exec $cont_id ip -br link | awk '$3 ~ /'$_mac_address'/ {print $1}')

  docker exec $cont_id $IPTABLES_BIN -t nat -A POSTROUTING -s $NAT_SUBNET -o ${_ifname%@*} \
    -j SNAT --to-source $_ip_address

  docker exec $cont_id $IPTABLES_BIN -t nat -A POSTROUTING -s $NAT_SUBNET -o ${_ifname%@*} \
    -j NFLOG --nflog-prefix "[POSTROUTING]:" --nflog-group 1
done

docker exec $cont_id $IPTABLES_BIN -A FORWARD -s $NAT_SUBNET -d 0/0 -j NFLOG --nflog-prefix "[ From NATed]:" --nflog-group 1
docker exec $cont_id $IPTABLES_BIN -A FORWARD -s 0/0 -d $NAT_SUBNET -j NFLOG --nflog-prefix "[   To NATed]:" --nflog-group 1

# docker exec -it $cont_id /bin/bash
