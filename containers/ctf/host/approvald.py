#!/usr/bin/env python3
"""Host-side approval daemon for the CTF lab (runs on the Mac, not in a container).

The gateway's egress proxy POSTs {"host", "port"} to /ask; this shows a native
macOS dialog and answers {"decision": "once" | "always" | "deny"}. It listens on
127.0.0.1 only and requires a shared secret, so nothing in the lab can approve
itself: the secret exists only in the gateway container, and the dev container
cannot reach this port (the firewall allows only the proxy uid to).
"""
import hmac
import json
import os
import re
import subprocess
import sys
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

SECRET = os.environ["CTF_APPROVAL_SECRET"]
PORT = int(os.environ.get("CTF_APPROVAL_PORT", "8765"))
HOST_RE = re.compile(r"^[A-Za-z0-9._-]{1,253}$")
dialog_lock = threading.Lock()  # one dialog at a time

SCRIPT = """on run argv
  set h to item 1 of argv
  try
    set r to display dialog ("The CTF lab wants to connect to:" & return & return & h) buttons {"Deny", "Allow this session", "Always allow"} default button "Deny" cancel button "Deny" with title "CTF egress" with icon caution giving up after 60
    if gave up of r then return "Deny"
    return button returned of r
  on error
    return "Deny"
  end try
end run"""
MAP = {"Allow this session": "once", "Always allow": "always"}


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        print("[approvald]", fmt % args, file=sys.stderr, flush=True)

    def do_POST(self):
        if self.path != "/ask" or not hmac.compare_digest(self.headers.get("X-Ctf-Secret", ""), SECRET):
            self.send_response(403)
            self.end_headers()
            return
        try:
            req = json.loads(self.rfile.read(int(self.headers.get("Content-Length", 0))))
            host, port = str(req["host"]), int(req["port"])
            if not HOST_RE.match(host):
                raise ValueError("bad host")
        except Exception:
            self.send_response(400)
            self.end_headers()
            return
        with dialog_lock:
            out = subprocess.run(
                ["osascript", "-e", SCRIPT, f"{host}:{port}"], capture_output=True, text=True
            ).stdout.strip()
        body = json.dumps({"decision": MAP.get(out, "deny")}).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


if __name__ == "__main__":
    ThreadingHTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
