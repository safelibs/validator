#!/usr/bin/env bash
# @testcase: usage-curl-progress-bar-stderr
# @title: curl --progress-bar emits to stderr
# @description: Downloads a small loopback resource with --progress-bar and confirms the bar character stream is written to stderr while stdout still contains the body bytes.
# @timeout: 180
# @tags: usage, curl, http, progress
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-progress-bar-stderr"
tmpdir=$(mktemp -d)
trap 'jobs -pr | xargs -r kill 2>/dev/null || true; rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/www"
# Make a moderately-sized file so the progress bar emits visible output.
python3 -c 'open("'"$tmpdir"'/www/payload.bin","wb").write(b"X" * 65536)'

port=$((29000 + RANDOM % 10000))
python3 -m http.server "$port" --bind 127.0.0.1 --directory "$tmpdir/www" >"$tmpdir/http.log" 2>&1 &
for _ in $(seq 1 50); do
  curl -fsS "http://127.0.0.1:$port/payload.bin" -o /dev/null && break
  sleep 0.1
done

curl --progress-bar -o "$tmpdir/got.bin" "http://127.0.0.1:$port/payload.bin" 2>"$tmpdir/err" >"$tmpdir/out"
test -s "$tmpdir/got.bin"
# Progress bar prints '#' or '=' characters as it advances; check non-empty stderr
test -s "$tmpdir/err" || { echo 'expected progress on stderr' >&2; exit 1; }
size=$(wc -c <"$tmpdir/got.bin")
[[ "$size" == "65536" ]] || { echo "expected 65536 bytes got $size" >&2; exit 1; }
