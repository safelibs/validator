#!/usr/bin/env bash
# @testcase: usage-curl-proxy-loopback-forward
# @title: curl --proxy through a loopback HTTP proxy
# @description: Routes curl through a small loopback HTTP proxy that rewrites the absolute-form request line to an origin server and asserts the proxied response body is returned.
# @timeout: 180
# @tags: usage, curl, http, proxy
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-proxy-loopback-forward"
tmpdir=$(mktemp -d)
origin_pid=""
proxy_pid=""
cleanup() {
  for p in "$proxy_pid" "$origin_pid"; do
    if [[ -n "$p" ]]; then
      kill "$p" 2>/dev/null || true
      wait "$p" 2>/dev/null || true
    fi
  done
  rm -rf "$tmpdir"
}
trap cleanup EXIT

cat >"$tmpdir/origin.py" <<'PYCASE'
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import os

class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        return

    def do_GET(self):
        body = ("origin-host=" + self.headers.get("Host", "") + "\npath=" + self.path + "\n").encode()
        self.send_response(200)
        self.send_header("Content-Type", "text/plain")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

ThreadingHTTPServer(("127.0.0.1", int(os.environ["PORT"])), Handler).serve_forever()
PYCASE

cat >"$tmpdir/proxy.py" <<'PYCASE'
import os
import socket
import socketserver
import urllib.request

ORIGIN = os.environ["ORIGIN"]

class ProxyHandler(socketserver.StreamRequestHandler):
    def handle(self):
        request_line = self.rfile.readline().decode("iso-8859-1").rstrip("\r\n")
        if not request_line:
            return
        method, target, _ = request_line.split(" ", 2)
        headers = {}
        while True:
            line = self.rfile.readline().decode("iso-8859-1")
            if line in ("\r\n", "\n", ""):
                break
            name, _, value = line.rstrip("\r\n").partition(":")
            headers[name.strip().lower()] = value.strip()
        # absolute-form target like http://host:port/path
        if target.startswith("http://"):
            rest = target[len("http://"):]
            slash = rest.find("/")
            path = rest[slash:] if slash >= 0 else "/"
        else:
            path = target
        upstream = ORIGIN.rstrip("/") + path
        req = urllib.request.Request(upstream, method=method)
        req.add_header("X-Proxied-By", "validator-loopback-proxy")
        with urllib.request.urlopen(req) as resp:
            body = resp.read()
            self.wfile.write(b"HTTP/1.1 200 OK\r\n")
            self.wfile.write(b"Content-Type: text/plain\r\n")
            self.wfile.write(b"X-Proxy-Marker: loopback-proxy\r\n")
            self.wfile.write(("Content-Length: %d\r\n\r\n" % len(body)).encode())
            self.wfile.write(body)

class Server(socketserver.ThreadingTCPServer):
    allow_reuse_address = True

Server(("127.0.0.1", int(os.environ["PORT"])), ProxyHandler).serve_forever()
PYCASE

origin_port=$((29000 + RANDOM % 5000))
proxy_port=$((34000 + RANDOM % 5000))
PORT="$origin_port" python3 "$tmpdir/origin.py" >"$tmpdir/origin.log" 2>&1 &
origin_pid=$!
for _ in $(seq 1 50); do
  if curl --noproxy '*' -fsS "http://127.0.0.1:$origin_port/" >/dev/null 2>&1; then
    break
  fi
  sleep 0.1
done

ORIGIN="http://127.0.0.1:$origin_port" PORT="$proxy_port" python3 "$tmpdir/proxy.py" >"$tmpdir/proxy.log" 2>&1 &
proxy_pid=$!
for _ in $(seq 1 50); do
  if (echo > /dev/tcp/127.0.0.1/$proxy_port) >/dev/null 2>&1; then
    break
  fi
  sleep 0.1
done

curl -fsS --proxy "http://127.0.0.1:$proxy_port" -i "http://127.0.0.1:$origin_port/echo" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'X-Proxy-Marker: loopback-proxy'
validator_assert_contains "$tmpdir/out" 'path=/echo'
