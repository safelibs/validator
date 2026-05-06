#!/usr/bin/env bash
# @testcase: usage-curl-r10-write-out-filename-effective
# @title: curl --write-out filename_effective matches -O target
# @description: Uses -O to download a file and asserts %{filename_effective} reports the basename derived from the URL path.
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
printf 'filename-effective-target\n' >"$tmpdir/srv/payload-r10.bin"
port=$((28800 + RANDOM % 8000))
( cd "$tmpdir/srv" && python3 -m http.server "$port" >/dev/null 2>&1 ) &
pid=$!
for _ in $(seq 1 50); do
  curl -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/payload-r10.bin" 2>/dev/null && break
  sleep 0.1
done

cd "$tmpdir"
fname=$(curl -fsS --max-time 5 -O -w '%{filename_effective}' "http://127.0.0.1:$port/payload-r10.bin")
[[ "$fname" == "payload-r10.bin" ]] || {
  printf 'expected filename_effective payload-r10.bin, got %q\n' "$fname" >&2
  exit 1
}
[[ -f "$tmpdir/payload-r10.bin" ]] || {
  printf 'expected downloaded file at %s\n' "$tmpdir/payload-r10.bin" >&2
  exit 1
}
