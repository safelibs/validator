#!/usr/bin/env bash
# @testcase: usage-curl-r16-output-flag-vs-remote-name
# @title: curl -o explicit filename and -O remote-name save identical bytes
# @description: Hosts a small payload and asserts that "-o local.bin" and "-O" (remote-name) both produce files with the same sha256 — locking in that the two output flags share the same underlying body bytes, only the destination filename differs.
# @timeout: 60
# @tags: usage, curl, output, remote-name
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
python3 -c "import sys; sys.stdout.buffer.write(bytes(range(0,256)))" >"$tmpdir/srv/payload-r16.bin"
expected=$(sha256sum "$tmpdir/srv/payload-r16.bin" | awk '{print $1}')

port=$((23800 + RANDOM % 19000))
( cd "$tmpdir/srv" && exec python3 -m http.server "$port" --bind 127.0.0.1 >/dev/null 2>&1 ) &
pid=$!
for _ in $(seq 1 60); do
    curl --noproxy '*' -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/" 2>/dev/null && break
    sleep 0.1
done

# -o path
curl --noproxy '*' -fsS --max-time 5 \
    -o "$tmpdir/explicit.bin" \
    "http://127.0.0.1:$port/payload-r16.bin"
sha_o=$(sha256sum "$tmpdir/explicit.bin" | awk '{print $1}')

# -O path (must cd to allow remote-name to drop in the working dir)
mkdir -p "$tmpdir/cap"
( cd "$tmpdir/cap" && curl --noproxy '*' -fsS --max-time 5 -O \
    "http://127.0.0.1:$port/payload-r16.bin" )
sha_O=$(sha256sum "$tmpdir/cap/payload-r16.bin" | awk '{print $1}')

[[ "$sha_o" == "$expected" ]]
[[ "$sha_O" == "$expected" ]]
[[ "$sha_o" == "$sha_O" ]]
