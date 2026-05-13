#!/usr/bin/env bash
# @testcase: usage-curl-r16-range-zero-nine-prefix
# @title: curl --range 0-9 fetches exactly the first ten bytes of a payload
# @description: Hosts a 64-byte payload on a loopback http.server, issues "curl --range 0-9", and asserts the downloaded body is exactly the first 10 bytes of the source payload byte-for-byte, locking in the explicit-prefix range form.
# @timeout: 60
# @tags: usage, curl, range, http
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
python3 -c "import sys; sys.stdout.write(''.join(chr(0x30 + (i % 10)) for i in range(64)))" \
    >"$tmpdir/srv/payload.bin"

port=$((23100 + RANDOM % 19000))
( cd "$tmpdir/srv" && exec python3 -m http.server "$port" --bind 127.0.0.1 >/dev/null 2>&1 ) &
pid=$!
for _ in $(seq 1 60); do
    curl --noproxy '*' -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/" 2>/dev/null && break
    sleep 0.1
done

curl --noproxy '*' -fsS --max-time 5 --range 0-9 \
    "http://127.0.0.1:$port/payload.bin" -o "$tmpdir/got.bin"

got_size=$(stat -c %s "$tmpdir/got.bin")
[[ "$got_size" -eq 10 ]]
head -c 10 "$tmpdir/srv/payload.bin" >"$tmpdir/expected.bin"
diff -q "$tmpdir/expected.bin" "$tmpdir/got.bin"
