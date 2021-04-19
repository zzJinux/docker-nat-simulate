#!/bin/sh

# Intended to be run on the Docker container

# Add a single SNAT rule and an additional log rule
set -eu

# Required parameters
#   IPTABLES
#   NAT_SUBNET
#   $1 : ip address of the subnet
#   $2 : the name of corresponding interface

IPADDR=$1
IFNAME=$2

$IPTABLES -t nat -A POSTROUTING -s $NAT_SUBNET -o $IFNAME \
  -j SNAT --to-source $IPADDR

# Not working
# $IPTABLES -t nat -A POSTROUTING -s $NAT_SUBNET -o $IFNAME \
#  -j NFLOG --nflog-prefix "[POSTROUTING]:" --nflog-group 1

