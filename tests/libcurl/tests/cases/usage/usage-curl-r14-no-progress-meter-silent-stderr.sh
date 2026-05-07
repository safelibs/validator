#!/usr/bin/env bash
# @testcase: usage-curl-r14-no-progress-meter-silent-stderr
# @title: curl --no-progress-meter suppresses the progress UI without --silent
# @description: Fetches a small file from a loopback HTTP server with curl --no-progress-meter (and without -s), captures stderr, and asserts the request succeeds with HTTP 200, the body matches the source byte-for-byte, and the recorded stderr contains no "Total" / "Speed" / "%" progress meter row characters.
# @timeout: 180
# @tags: usage, curl, http, progress
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
python3 -c 'import sys
sys.stdout.buffer.write(b"r14 no-progress-meter row\n" * 200)' >"$tmpdir/srv/payload.txt"
port=$((23000 + RANDOM % 19000))
( cd "$tmpdir/srv" && exec python3 -m http.server "$port" >/dev/null 2>&1 ) &
pid=$!
for _ in $(seq 1 60); do
    curl --noproxy '*' -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/" 2>/dev/null && break
    sleep 0.1
done

code=$(curl --noproxy '*' --max-time 5 --no-progress-meter \
    -o "$tmpdir/got.txt" -w '%{http_code}' \
    "http://127.0.0.1:$port/payload.txt" 2>"$tmpdir/stderr.log")
[[ "$code" == "200" ]] || {
    printf 'expected 200, got %q\n' "$code" >&2
    cat "$tmpdir/stderr.log" >&2
    exit 1
}
diff -q "$tmpdir/srv/payload.txt" "$tmpdir/got.txt"

# Progress meter rows would carry "Total" / "Speed" / "Dload" headings.
if grep -Eq 'Total[[:space:]]+Received[[:space:]]+Xferd|Dload[[:space:]]+Upload' "$tmpdir/stderr.log"; then
    printf 'unexpected progress-meter heading on stderr with --no-progress-meter\n' >&2
    cat "$tmpdir/stderr.log" >&2
    exit 1
fi
