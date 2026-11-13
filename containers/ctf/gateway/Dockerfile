FROM debian:stable-slim
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      openconnect vpnc-scripts nftables dnsmasq iproute2 procps util-linux \
      python3 python3-dnspython ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --system --uid 5000 --no-create-home --shell /usr/sbin/nologin ctfproxy \
    && mkdir -p /etc/ctf /var/lib/ctf /run/ctf \
    && chown ctfproxy /var/lib/ctf
COPY proxy.py /usr/local/bin/proxy.py
COPY entrypoint.sh vpn-script healthcheck dns-reload /usr/local/bin/
COPY allow.txt /etc/ctf/allow.txt
RUN chmod 0755 /usr/local/bin/entrypoint.sh /usr/local/bin/vpn-script \
      /usr/local/bin/healthcheck /usr/local/bin/dns-reload /usr/local/bin/proxy.py
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
