#!/usr/bin/env bash
# @testcase: usage-curl-r9-write-out-size-download
# @title: curl --write-out reports size_download
# @description: Downloads a known-length payload from a loopback server and verifies curl emits the exact byte count via %{size_download}.
# @timeout: 180
# @tags: usage, curl, http
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
# 100-byte payload (with trailing newline added by yes pipe).
head -c 100 /dev/urandom | base64 | head -c 100 >"$tmpdir/srv/payload.bin"
sz=$(wc -c <"$tmpdir/srv/payload.bin")

port=$((24000 + RANDOM % 8000))
( cd "$tmpdir/srv" && python3 -m http.server "$port" >/dev/null 2>&1 ) &
pid=$!
for _ in $(seq 1 50); do
  curl -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/payload.bin" >/dev/null 2>&1 && break
  sleep 0.1
done

reported=$(curl -fsS --max-time 5 -o /dev/null -w '%{size_download}' "http://127.0.0.1:$port/payload.bin")
[[ "$reported" == "$sz" ]] || {
  printf 'expected %s, got %s\n' "$sz" "$reported" >&2
  exit 1
}
