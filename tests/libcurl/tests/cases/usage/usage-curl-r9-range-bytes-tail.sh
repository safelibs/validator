#!/usr/bin/env bash
# @testcase: usage-curl-r9-range-bytes-tail
# @title: curl --range fetches trailing bytes
# @description: Requests the trailing 5 bytes of a known payload via --range against a loopback server and validates the partial response matches the file tail.
# @timeout: 180
# @tags: usage, curl, http, range
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
printf 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' >"$tmpdir/srv/data.bin"

port=$((24500 + RANDOM % 8000))
( cd "$tmpdir/srv" && python3 -m http.server "$port" >/dev/null 2>&1 ) &
pid=$!
for _ in $(seq 1 50); do
  curl -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/data.bin" 2>/dev/null && break
  sleep 0.1
done

curl -fsS --max-time 5 --range 21- -o "$tmpdir/tail" "http://127.0.0.1:$port/data.bin"
got=$(cat "$tmpdir/tail")
[[ "$got" == "VWXYZ" ]] || {
  printf 'expected VWXYZ, got %s\n' "$got" >&2
  exit 1
}
