#!/usr/bin/env bash
# @testcase: usage-curl-r11-max-filesize-rejects-large
# @title: curl --max-filesize aborts download when Content-Length exceeds the cap
# @description: Hosts a 100-byte file on a loopback server and asserts curl --max-filesize 5 exits with code 63 (CURLE_FILESIZE_EXCEEDED) and writes nothing to the output file.
# @timeout: 180
# @tags: usage, curl, http, max-filesize
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
# 100 'A' bytes plus newline → 101 bytes; well above the 5-byte cap.
printf '%0.s'A {1..100} >"$tmpdir/srv/big.bin"
port=$((28800 + RANDOM % 8000))
( cd "$tmpdir/srv" && python3 -m http.server "$port" >/dev/null 2>&1 ) &
pid=$!
for _ in $(seq 1 50); do
  curl -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/big.bin" 2>/dev/null && break
  sleep 0.1
done

set +e
curl -sS --max-time 5 --max-filesize 5 -o "$tmpdir/out.bin" "http://127.0.0.1:$port/big.bin"
ec=$?
set -e
[[ $ec -eq 63 ]] || {
  printf 'expected curl exit 63 (CURLE_FILESIZE_EXCEEDED), got %d\n' "$ec" >&2
  exit 1
}
[[ ! -s "$tmpdir/out.bin" ]] || {
  printf 'expected output file to be empty, got %d bytes\n' "$(wc -c <"$tmpdir/out.bin")" >&2
  exit 1
}
