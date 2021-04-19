FROM debian:buster

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get -y install iptables ulogd2

COPY *.sh /scripts/
COPY ulogd.conf /etc/ulogd.conf
ENV IPTABLES=iptables-legacy

CMD ["ulogd"]
