#!/bin/sh
# Gateway start-up. Order matters: the firewall goes up BEFORE anything can
# talk, so there is never a window in which traffic leaks outside the tunnel.
set -eu

: "${VPN_SERVER:?}" "${VPN_USER:?}" "${APPROVAL_URL:?}" "${APPROVAL_SECRET:?}"
VPN_PORT=${VPN_PORT:-443}
PROXY_UID=5000

if [ -z "${VPN_PASSWORD:-}" ]; then
  echo "VPN_PASSWORD missing (run: ctf secrets)" >&2
  exit 1
fi

# --- resolve the two off-tunnel destinations while Docker's DNS still works ---
VPN_IP=$(getent ahostsv4 "$VPN_SERVER" | awk 'NR==1{print $1}')
approval_host=$(printf '%s' "$APPROVAL_URL" | sed -E 's#^[a-z]+://([^:/]+).*#\1#')
approval_port=$(printf '%s' "$APPROVAL_URL" | sed -nE 's#^[a-z]+://[^:/]+:([0-9]+).*#\1#p')
APPROVAL_IP=$(getent ahostsv4 "$approval_host" | awk 'NR==1{print $1}')
APPROVAL_PORT=${approval_port:-80}
# The proxy cannot resolve names once DNS is locked down, so hand it the IP.
APPROVAL_URL=$(printf '%s' "$APPROVAL_URL" | sed -E "s#//[^:/]+#//$APPROVAL_IP#")
[ -n "$VPN_IP" ] && [ -n "$APPROVAL_IP" ] || { echo "cannot resolve VPN server or approval host" >&2; exit 1; }

# --- firewall / kill switch ---------------------------------------------------
# Output policy is drop. Allowed: loopback, the tunnel, root (openconnect) to
# the VPN server only, and the proxy uid to the public internet (never to
# private ranges) plus the approval daemon.
nft -f - <<EOF
table inet ctf {
  chain input {
    type filter hook input priority 0; policy drop;
    iif lo accept
    ct state established,related accept
    iifname "tun0" accept
  }
  chain forward {
    type filter hook forward priority 0; policy drop;
  }
  chain output {
    type filter hook output priority 0; policy drop;
    oif lo accept
    ct state established,related accept
    oifname "tun0" accept
    meta skuid 0 ip daddr $VPN_IP tcp dport $VPN_PORT accept
    meta skuid 0 ip daddr $VPN_IP udp dport $VPN_PORT accept
    meta skuid $PROXY_UID ip daddr $APPROVAL_IP tcp dport $APPROVAL_PORT accept
    meta skuid $PROXY_UID ip daddr { 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, 169.254.0.0/16, 100.64.0.0/10 } drop
    meta skuid $PROXY_UID oifname "eth0" accept
  }
}
EOF

# The proxy must leave through eth0 even when the VPN pushes a default route
# into tun0, so route its uid via the container's original gateway.
GW=$(ip -4 route show default | awk '{print $3; exit}')
ip -4 route add default via "$GW" dev eth0 table 100
ip -4 rule add uidrange $PROXY_UID-$PROXY_UID lookup 100 priority 100

# --- DNS: only the VPN's DNS answers, and only for the configured domains ----
printf 'nameserver 127.0.0.1\noptions timeout:2 attempts:1\n' > /etc/resolv.conf
dns-reload

# --- egress proxy + key-injecting reverse proxy (unprivileged uid) ------------
setpriv --reuid=$PROXY_UID --regid=$PROXY_UID --clear-groups \
  env APPROVAL_URL="$APPROVAL_URL" APPROVAL_SECRET="$APPROVAL_SECRET" \
      OPENROUTER_API_KEY="${OPENROUTER_API_KEY:-}" DEEPSEEK_API_KEY="${DEEPSEEK_API_KEY:-}" \
      python3 /usr/local/bin/proxy.py &

# --- VPN, forever: a dropped tunnel leaves the kill switch in place -----------
trap 'kill $(jobs -p) 2>/dev/null; exit 0' TERM INT
while true; do
  printf '%s\n' "$VPN_PASSWORD" | openconnect \
    --protocol="${VPN_PROTOCOL:-anyconnect}" \
    --user="$VPN_USER" --passwd-on-stdin --non-inter \
    --resolve="$VPN_SERVER:$VPN_IP" \
    --interface=tun0 \
    --script=/usr/local/bin/vpn-script \
    ${VPN_EXTRA_ARGS:-} \
    "https://$VPN_SERVER:$VPN_PORT" &
  wait $! || true
  echo "openconnect exited; reconnecting in 5s (traffic stays blocked)" >&2
  sleep 5
done
