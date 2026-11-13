#!/usr/bin/env python3
"""Egress proxy for the CTF lab (runs as the unprivileged `proxy` uid).

:3128  forward proxy (HTTP CONNECT + plain http://). Every destination host not
       already allowed asks the host-side approval daemon (macOS dialog):
       allow this session / always allow / deny. Names are resolved HERE, over the
       public internet; destinations that resolve to private/loopback space are
       refused, so the proxy cannot be used to reach the VM or your LAN.
:8080  reverse proxy for the LLM APIs. Injects the real API key, so the dev
       container only ever holds a dummy key.
         /openrouter/...  -> https://openrouter.ai/...
         /deepseek/...    -> https://api.deepseek.com/...
"""
import asyncio
import ipaddress
import json
import os
import re
import ssl
import sys
import time
import urllib.request

import dns.resolver

STATE = "/var/lib/ctf"
ALLOW_FILE = f"{STATE}/allow.txt"
STATIC_ALLOW = "/etc/ctf/allow.txt"
APPROVAL_URL = os.environ["APPROVAL_URL"].rstrip("/")
APPROVAL_SECRET = os.environ["APPROVAL_SECRET"]

ROUTES = {
    "/openrouter/": ("openrouter.ai", os.environ.get("OPENROUTER_API_KEY", "")),
    "/deepseek/": ("api.deepseek.com", os.environ.get("DEEPSEEK_API_KEY", "")),
}

resolver = dns.resolver.Resolver(configure=False)
resolver.nameservers = ["1.1.1.1", "9.9.9.9"]
resolver.lifetime = 5

HOST_RE = re.compile(r"^[A-Za-z0-9._-]{1,253}$")
locks: dict[str, asyncio.Lock] = {}
denied_until: dict[str, float] = {}
session_allowed: set[str] = set()


def log(*a):
    print("[proxy]", *a, file=sys.stderr, flush=True)


def read_list(path):
    try:
        with open(path) as f:
            return {l.strip().lower() for l in f if l.strip() and not l.startswith("#")}
    except FileNotFoundError:
        return set()


def listed(host: str) -> bool:
    host = host.lower()
    if host in session_allowed:
        return True
    for entry in read_list(STATIC_ALLOW) | read_list(ALLOW_FILE):
        if host == entry or host.endswith("." + entry):
            return True
    return False


def ask_host(host: str, port: int) -> str:
    req = urllib.request.Request(
        APPROVAL_URL + "/ask",
        data=json.dumps({"host": host, "port": port}).encode(),
        headers={"X-Ctf-Secret": APPROVAL_SECRET, "Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(req, timeout=90) as r:
            return json.load(r).get("decision", "deny")
    except Exception as e:  # unreachable daemon = deny
        log("approval daemon unreachable:", e)
        return "deny"


async def approved(host: str, port: int) -> bool:
    if listed(host):
        return True
    if denied_until.get(host, 0) > time.time():
        return False
    lock = locks.setdefault(host, asyncio.Lock())
    async with lock:  # one dialog per host, however many requests pile up
        if listed(host):
            return True
        decision = await asyncio.get_running_loop().run_in_executor(None, ask_host, host, port)
        log("decision", host, port, decision)
        if decision == "always":
            with open(ALLOW_FILE, "a") as f:
                f.write(host.lower() + "\n")
            return True
        if decision == "once":
            session_allowed.add(host.lower())  # lasts until the gateway restarts
            return True
        denied_until[host] = time.time() + 60
        return False


def resolve_sync(host: str):
    try:
        ipaddress.ip_address(host)
        return host
    except ValueError:
        pass
    for rr in resolver.resolve(host, "A"):
        return rr.address
    return None


async def resolve_public(host: str):
    ip = await asyncio.get_running_loop().run_in_executor(None, resolve_sync, host)
    if not ip or not ipaddress.ip_address(ip).is_global:
        return None
    return ip


async def pipe(r, w):
    try:
        while True:
            data = await r.read(65536)
            if not data:
                break
            w.write(data)
            await w.drain()
    except Exception:
        pass


async def relay(cr, cw, ur, uw):
    tasks = [asyncio.ensure_future(pipe(cr, uw)), asyncio.ensure_future(pipe(ur, cw))]
    await asyncio.wait(tasks, return_when=asyncio.FIRST_COMPLETED)
    for t in tasks:
        t.cancel()
    for w in (cw, uw):
        try:
            w.close()
        except Exception:
            pass


async def read_head(reader):
    raw = await asyncio.wait_for(reader.readuntil(b"\r\n\r\n"), 30)
    lines = raw[:-4].decode("latin-1").split("\r\n")
    headers = [tuple(l.split(":", 1)) for l in lines[1:] if ":" in l]
    return lines[0], [(k.strip(), v.strip()) for k, v in headers]


def reply(w, code, msg):
    body = msg.encode()
    w.write(
        f"HTTP/1.1 {code} {msg}\r\nContent-Length: {len(body)}\r\nConnection: close\r\n\r\n".encode() + body
    )


async def handle_forward(cr, cw):
    try:
        line, headers = await read_head(cr)
        method, target, version = line.split(" ", 2)
        if method == "CONNECT":
            host, _, port = target.rpartition(":")
            port = int(port or 443)
            tls = None
            path = None
        else:
            m = re.match(r"^http://([^/:]+)(?::(\d+))?(/.*)?$", target)
            if not m:
                return reply(cw, 400, "proxy needs absolute http:// URI")
            host, port, path = m.group(1), int(m.group(2) or 80), m.group(3) or "/"
        if not HOST_RE.match(host):
            return reply(cw, 400, "bad host")
        try:
            if not ipaddress.ip_address(host).is_global:  # never ask about private IPs
                return reply(cw, 403, "private addresses are not proxied")
        except ValueError:
            pass
        if not await approved(host, port):
            return reply(cw, 403, "blocked by CTF egress policy")
        ip = await resolve_public(host)
        if not ip:
            return reply(cw, 502, "cannot resolve to a public address")
        ur, uw = await asyncio.open_connection(ip, port)
        if method == "CONNECT":
            cw.write(b"HTTP/1.1 200 Connection established\r\n\r\n")
        else:
            drop = {"proxy-connection", "connection", "proxy-authorization"}
            hdr = "".join(f"{k}: {v}\r\n" for k, v in headers if k.lower() not in drop)
            uw.write(f"{method} {path} {version}\r\n{hdr}Connection: close\r\n\r\n".encode("latin-1"))
        await relay(cr, cw, ur, uw)
    except Exception as e:
        log("forward error:", repr(e))
    finally:
        try:
            cw.close()
        except Exception:
            pass


async def handle_reverse(cr, cw):
    try:
        line, headers = await read_head(cr)
        method, target, version = line.split(" ", 2)
        for prefix, (host, key) in ROUTES.items():
            if target.startswith(prefix):
                break
        else:
            return reply(cw, 404, "unknown route")
        if not key:
            return reply(cw, 503, f"no API key configured for {host}")
        ip = await resolve_public(host)
        if not ip:
            return reply(cw, 502, "cannot resolve upstream")
        ur, uw = await asyncio.open_connection(ip, 443, ssl=ssl.create_default_context(), server_hostname=host)
        drop = {"host", "authorization", "x-api-key", "connection", "proxy-connection"}
        hdr = "".join(f"{k}: {v}\r\n" for k, v in headers if k.lower() not in drop)
        uw.write(
            f"{method} /{target[len(prefix):]} {version}\r\nHost: {host}\r\n"
            f"Authorization: Bearer {key}\r\n{hdr}Connection: close\r\n\r\n".encode("latin-1")
        )
        await relay(cr, cw, ur, uw)
    except Exception as e:
        log("reverse error:", repr(e))
    finally:
        try:
            cw.close()
        except Exception:
            pass


async def main():
    fwd = await asyncio.start_server(handle_forward, "127.0.0.1", 3128)
    rev = await asyncio.start_server(handle_reverse, "127.0.0.1", 8080)
    log("listening on 127.0.0.1:3128 (egress) and :8080 (LLM)")
    async with fwd, rev:
        await asyncio.gather(fwd.serve_forever(), rev.serve_forever())


if __name__ == "__main__":
    asyncio.run(main())
