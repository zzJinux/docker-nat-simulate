#!/bin/sh

# Intended to be run on the Docker container
set -eu

# Required parameters
#   IPTABLES
#   NAT_SUBNET
#   $1 : Path to a file containing a list of "<subnet_ip> <subnet_mac>" lines


# IP Address that belongs to NATed subnet
while read subnet_item; do echo $subnet_item | {
  read ipaddr macaddr
  ifname=$(ip -br link | awk '$3 ~ /'$macaddr'/ {print $1}')
  ifname=${ifname%@*}

  ./ipt_add_rule.sh $ipaddr $ifname
} done <"$1"

# $IPTABLES -A FORWARD -s $NAT_SUBNET -d 0/0 -j NFLOG --nflog-prefix "[ From inside]:" --nflog-group 1
# $IPTABLES -A FORWARD -s 0/0 -d $NAT_SUBNET -j NFLOG --nflog-prefix "[   To inside]:" --nflog-group 1
