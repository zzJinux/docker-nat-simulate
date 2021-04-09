###### `ulogd`
The router container requires "ulogd" package in addition to "iptables"
(For ulogd configuration, see https://hangarau.space/running-and-debugging-iptables-inside-a-docker-container/)

```
IPT -I FORWARD -s 0/0 -d 0/0 -j NFLOG --nflog-prefix "[default]:" --nflog-group 1
# Log all forwarded packets
```

The logs will apear at `/var/log/ulogd_syslogemu.log`

###### `ip-route`
Add a route to the <subnet> network through the eth0 network interface using <ip addr> as a gateway
```
ip route add <subnet> via <ip addr> dev eth0
```

Run it on "host" containers
