FROM debian:buster

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get -y install iptables ulogd2
COPY ulogd.conf /etc/ulogd.conf
CMD ["ulogd"]
