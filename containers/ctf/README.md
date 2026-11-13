# CTF lab

Isolated Kali workstation on a VPN tunnel. Lives in `nix-config/containers/ctf`;
the host side (the `ctf` Colima VM) is `modules/home/ctf.nix`. Your files go in
`~/ctf/work` (outside any repo).

```
 Mac ── Colima VM "ctf" (mounts only ~/ctf/work)
          ├─ gateway  openconnect · nftables kill switch · DNS · egress proxy · key proxy
          └─ dev      Kali + python + opencode   (shares the gateway's network namespace)
 Mac ── host/approvald.py  macOS "allow this host?" dialog
```

## First time

```bash
cd containers/ctf
cp .env.example .env && $EDITOR .env     # VPN server, user, protocol
bin/ctf secrets                           # Keychain: VPN password, API keys
bin/ctf up
bin/ctf shell                             # tmux in the dev container; run `opencode`
```

## What is enforced

- **Files:** the VM mounts only `~/ctf/work`. Nothing else on the Mac is reachable.
- **Network:** gateway output policy is drop. Allowed: the tunnel (`tun0`), root
  to the VPN server only, and the proxy uid to the public internet. If the VPN
  drops, everything stays blocked (kill switch).
- **New hosts:** any non-tunnel destination goes through the proxy and pops a
  dialog on the Mac: Deny / Allow this session / Always allow (`bin/ctf allowed`).
- **DNS:** only `CTF_DNS_DOMAINS` resolve, via the VPN's DNS. No DNS tunnelling.
- **LLM keys:** live only in the gateway; opencode talks to
  `127.0.0.1:8080/{deepseek,openrouter}` with a dummy key.
- **dev:** non-root, all capabilities dropped, `no-new-privileges`, SSH agent not forwarded.

## Known limits (read these)

- **Inside the tunnel is unrestricted** (reverse shells need inbound too). The
  agent can touch anything the VPN routes to: stay in scope.
- **`~/ctf/work` is writable from the lab.** Treat its contents as untrusted; never
  run them on the Mac.
- **No NET_RAW** on dev, because AF_PACKET sockets bypass nftables. So: `nmap -sT`
  (not `-sS`), no scapy sniffing. ICMP ping works.
- The dev container's `NO_PROXY` sends private ranges around the proxy; extend
  it for unusual CTF address space.
- A spend-capped API key is still a key: cap it.
