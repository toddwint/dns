FROM toddwint/mybaseimage
COPY app /opt/dns
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=UTC \
    HTTPPORT1=8080 \
    HTTPPORT2=8081 \
    HTTPPORT3=8082 \
    HTTPPORT4=8083 \
    HUID=1001 \
    HGID=1001 \
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
