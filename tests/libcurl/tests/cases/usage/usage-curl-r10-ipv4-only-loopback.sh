#!/usr/bin/env bash
# @testcase: usage-curl-r10-ipv4-only-loopback
# @title: curl -4 forces IPv4 path against localhost
# @description: Resolves localhost with -4 (--ipv4) to ensure curl picks the IPv4 loopback and reports remote_ip 127.0.0.1 in --write-out.
# @timeout: 180
# @tags: usage, curl, http, ipv4
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
pid=""
cleanup() {
  if [[ -n "$pid" ]]; then kill "$pid" 2>/dev/null || true; wait "$pid" 2>/dev/null || true; fi
  rm -rf "$tmpdir"
}
trap cleanup EXIT

mkdir -p "$tmpdir/srv"
printf 'ipv4-only-target\n' >"$tmpdir/srv/index.html"
port=$((29400 + RANDOM % 8000))
( cd "$tmpdir/srv" && python3 -m http.server --bind 127.0.0.1 "$port" >/dev/null 2>&1 ) &
pid=$!
for _ in $(seq 1 50); do
  curl -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/" 2>/dev/null && break
  sleep 0.1
done

ip=$(curl -fsS --max-time 5 -4 -o /dev/null -w '%{remote_ip}' "http://localhost:$port/")
[[ "$ip" == "127.0.0.1" ]] || {
  printf 'expected remote_ip 127.0.0.1 with -4, got %q\n' "$ip" >&2
  exit 1
}
