#!/usr/bin/env bash
# @testcase: usage-curl-r14-connect-to-redirects-host
# @title: curl --connect-to redirects the TCP target while preserving the request URL host
# @description: Starts a loopback HTTP server on a high port and uses curl --connect-to "example.com:80:127.0.0.1:<port>" with a request URL of http://example.com/ to make curl connect to the loopback server while still emitting Host: example.com in the request line. Asserts the response is 200 and the body matches the served file.
# @timeout: 180
# @tags: usage, curl, http, connect-to
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
printf 'r14 connect-to body\n' >"$tmpdir/srv/payload.txt"
port=$((23000 + RANDOM % 19000))
( cd "$tmpdir/srv" && exec python3 -m http.server "$port" >/dev/null 2>&1 ) &
pid=$!
for _ in $(seq 1 60); do
    curl --noproxy '*' -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/" 2>/dev/null && break
    sleep 0.1
done

code=$(curl --noproxy '*' -sS --max-time 5 \
    --connect-to "example.com:80:127.0.0.1:$port" \
    -o "$tmpdir/got.txt" -w '%{http_code}' \
    "http://example.com/payload.txt")
[[ "$code" == "200" ]] || {
    printf 'expected 200 from --connect-to, got %q\n' "$code" >&2
    exit 1
}
diff -q "$tmpdir/srv/payload.txt" "$tmpdir/got.txt"
