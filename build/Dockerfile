FROM toddwint/mybaseimage
COPY app /opt/dns
LABEL LICENSE="GPL-3.0-or-later"
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    TZ=UTC \
    HTTPPORT1=8080 \
    HTTPPORT2=8081 \
    HTTPPORT3=8082 \
    HTTPPORT4=8083 \
    HUID=0 \
    HGID=0 \
    HOSTNAME=dnssrvr \
    APPNAME=dns
RUN apt-get update \
    && \
    apt-get install -y \
    dnsmasq \
    && \
    echo $HOSTNAME > /etc/hostname \
    && \
    apt-get autoremove -y \
    && \
    rm -rf /var/lib/apt/lists/*
WORKDIR /opt/dns/debug
CMD ["/opt/dns/scripts/startup.sh"]
