#!/usr/bin/env bash
# @testcase: usage-curl-r10-write-out-local-ip-loopback
# @title: curl --write-out reports local_ip and local_port for loopback
# @description: Verifies that --write-out exposes %{local_ip}=127.0.0.1 for a loopback HTTP transfer and that %{local_port} is a non-zero numeric ephemeral port.
# @timeout: 180
# @tags: usage, curl, http, write-out
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
printf 'local-ip-target\n' >"$tmpdir/srv/index.html"
port=$((28400 + RANDOM % 8000))
( cd "$tmpdir/srv" && python3 -m http.server "$port" >/dev/null 2>&1 ) &
pid=$!
for _ in $(seq 1 50); do
  curl -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/" 2>/dev/null && break
  sleep 0.1
done

out=$(curl -fsS --max-time 5 -o /dev/null -w '%{local_ip} %{local_port}' "http://127.0.0.1:$port/")
local_ip=${out% *}
local_port=${out##* }
[[ "$local_ip" == "127.0.0.1" ]] || {
  printf 'expected local_ip 127.0.0.1, got %q\n' "$local_ip" >&2
  exit 1
}
[[ "$local_port" =~ ^[0-9]+$ ]] || {
  printf 'expected numeric local_port, got %q\n' "$local_port" >&2
  exit 1
}
[[ "$local_port" -gt 0 ]]
