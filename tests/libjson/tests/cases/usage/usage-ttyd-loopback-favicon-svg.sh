#!/usr/bin/env bash
# @testcase: usage-ttyd-loopback-favicon-svg
# @title: ttyd serves index.html on loopback root
# @description: Starts ttyd on loopback and verifies that GET / returns a 2xx HTML payload large enough to be the bundled SPA index, not an empty stub.
# @timeout: 180
# @tags: usage, ttyd, http
# @client: ttyd

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
pid=""
cleanup() {
  if [[ -n "$pid" ]]; then
    kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
  fi
  rm -rf "$tmpdir"
}
trap cleanup EXIT

port=$((23000 + RANDOM % 20000))
ttyd -i 127.0.0.1 -p "$port" bash -lc 'printf hi' >"$tmpdir/ttyd.log" 2>&1 &
pid=$!

ready=0
for _ in $(seq 1 40); do
  if curl -fsSI "http://127.0.0.1:$port/" >/dev/null 2>&1; then
    ready=1
    break
  fi
  sleep 0.25
done
[[ "$ready" == "1" ]] || { sed -n '1,80p' "$tmpdir/ttyd.log" >&2; exit 1; }

# Root index returns a 2xx HTML payload.
http_code=$(curl -s -o "$tmpdir/index.html" -w '%{http_code}' "http://127.0.0.1:$port/")
[[ "$http_code" =~ ^2[0-9][0-9]$ ]] || { printf 'http %s\n' "$http_code" >&2; exit 1; }
[[ -s "$tmpdir/index.html" ]] || { printf 'empty index\n' >&2; exit 1; }
grep -qi '<html' "$tmpdir/index.html"
