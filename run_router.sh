#!/usr/bin/env bash
set -e

if [ $# -eq 0 ]; then
  echo "Usage: ./run_router.sh <network_name1> [ <network_name2> ... ]" 2>&1
fi

DOCKERFILE_DIR=router
IMAGE_NAME=netsim_router
NAT_SUBNET_NAME=$1; shift
NAT_SUBNET=$(docker network inspect -f '{{(index .IPAM.Config 0).Subnet}}' $NAT_SUBNET_NAME)
# IPTABLES: Set to override the build-time IPTABLES env var

# Build the image if not exist
if ! docker image inspect -f '{{ .Name }}' $IMAGE_NAME >/dev/null 2>&1; then
  docker build -f $DOCKERFILE_DIR/Dockerfile -t $IMAGE_NAME $DOCKERFILE_DIR
  echo
fi

# Create a container
cont_envs=(-e NAT_SUBNET=$NAT_SUBNET)
if [ $IPTABLES ]; then
  cont_envs+=(-e IPTABLES=$IPTABLES)
fi

cont_id=$(
  docker create --rm --cap-add=NET_ADMIN \
  --network=$NAT_SUBNET_NAME \
  "${cont_envs[@]}" \
  $IMAGE_NAME
)


# Connect remaining networks
for subnet_name in "$@"; do
  docker network connect $subnet_name $cont_id
done


docker start $cont_id &>/dev/null
ipaddr_natside=$(docker container inspect -f "{{.NetworkSettings.Networks.${NAT_SUBNET_NAME}.IPAddress}}" $cont_id)


echo 'Container ID'
echo -e "\t$cont_id"
echo "IP Address ($NAT_SUBNET_NAME)"
echo -e "\t$ipaddr_natside"

for subnet_name in "$@"; do
  ipaddr=$(docker container inspect -f "{{.NetworkSettings.Networks.$subnet_name.IPAddress}}" $cont_id)

  echo "IP Address ($subnet_name)"
  echo -e "\t$ipaddr"
done
echo

echo 'Configuring iptables...'
router/get_subnets.sh $cont_id "$@" | docker exec -i $cont_id /bin/bash -c 'cat >/subnets.txt'
docker exec -w /scripts $cont_id ./ipt_setup.sh /subnets.txt

# docker exec -it $cont_id /bin/bash
