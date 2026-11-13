FROM kalilinux/kali-rolling
ENV DEBIAN_FRONTEND=noninteractive

# Kali's top-10 plus the web/general tooling. No NET_RAW at runtime (see
# README): nmap uses connect scans (-sT), ping works through ping_group_range.
RUN apt-get update && apt-get install -y --no-install-recommends \
      kali-tools-top10 \
      python3 python3-pip python3-venv git tmux vim curl wget ca-certificates \
      iputils-ping iproute2 dnsutils netcat-openbsd socat ncat \
      ffuf gobuster mitmproxy sqlmap whatweb \
      nodejs npm build-essential python3-dev \
      python3-pwntools python3-unicorn python3-impacket python3-gmpy2 python3-pycryptodome \
      python3-requests python3-bs4 ipython3 \
    && rm -rf /var/lib/apt/lists/*

# Python for CTFs, in a venv (Kali enforces PEP 668).
# pwntools/unicorn/impacket come from Kali's apt (unicorn does not build from
# source on arm64); the venv sees them and holds the pip-only extras.
RUN python3 -m venv --system-site-packages /opt/venv \
    && /opt/venv/bin/pip install --no-cache-dir z3-solver

# opencode, configured for the gateway's key-injecting reverse proxy.
RUN npm install -g opencode-ai \
    && (cd /usr/local/lib/node_modules/opencode-ai && node postinstall.mjs)
COPY opencode.json /etc/ctf/opencode.json

RUN useradd -m -u 1000 -s /bin/bash ctf
COPY tmux.conf /home/ctf/.tmux.conf
COPY apt-proxy.conf /etc/apt/apt.conf.d/99proxy
RUN chown ctf:ctf /home/ctf/.tmux.conf

# Everything not on the tunnel goes through the gateway's approval proxy.
# Private ranges (the CTF network) bypass it and ride the VPN directly.
ENV PATH=/opt/venv/bin:$PATH \
    OPENCODE_CONFIG=/etc/ctf/opencode.json \
    HTTP_PROXY=http://127.0.0.1:3128 HTTPS_PROXY=http://127.0.0.1:3128 \
    http_proxy=http://127.0.0.1:3128 https_proxy=http://127.0.0.1:3128 \
    NO_PROXY=localhost,127.0.0.1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,.htb,.local \
    no_proxy=localhost,127.0.0.1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,.htb,.local

USER ctf
WORKDIR /work
