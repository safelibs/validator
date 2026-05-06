#!/usr/bin/env bash
# @testcase: usage-curl-r10-write-out-remote-ip-loopback
# @title: curl --write-out reports remote_ip and remote_port for loopback
# @description: Asserts that --write-out exposes %{remote_ip}=127.0.0.1 and %{remote_port} matching the loopback server port for an HTTP/1.1 request.
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
printf 'remote-ip-target\n' >"$tmpdir/srv/index.html"
port=$((28200 + RANDOM % 8000))
( cd "$tmpdir/srv" && python3 -m http.server "$port" >/dev/null 2>&1 ) &
pid=$!
for _ in $(seq 1 50); do
  curl -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/" 2>/dev/null && break
  sleep 0.1
done

out=$(curl -fsS --max-time 5 -o /dev/null -w '%{remote_ip} %{remote_port}' "http://127.0.0.1:$port/")
remote_ip=${out% *}
remote_port=${out##* }
[[ "$remote_ip" == "127.0.0.1" ]] || {
  printf 'expected remote_ip 127.0.0.1, got %q\n' "$remote_ip" >&2
  exit 1
}
[[ "$remote_port" == "$port" ]] || {
  printf 'expected remote_port %s, got %q\n' "$port" "$remote_port" >&2
  exit 1
}
