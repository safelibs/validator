#!/usr/bin/env bash
# @testcase: usage-curl-r13-keepalive-time-accepted
# @title: curl --keepalive-time 60 is accepted and completes the loopback transfer
# @description: Fetches a loopback URL with curl --keepalive-time 60 and asserts the response code is 200 and the body matches the served file. Verifies the option is parsed and applied without breaking a normal transfer.
# @timeout: 180
# @tags: usage, curl, http, keepalive
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
printf 'r13 keepalive-time body\n' >"$tmpdir/srv/payload.txt"
port=$((23000 + RANDOM % 19000))
( cd "$tmpdir/srv" && python3 -m http.server "$port" >/dev/null 2>&1 ) &
pid=$!
for _ in $(seq 1 60); do
    curl --noproxy '*' -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/" 2>/dev/null && break
    sleep 0.1
done

code=$(curl --noproxy '*' -sS --max-time 5 --keepalive-time 60 \
    -o "$tmpdir/got.txt" -w '%{http_code}' "http://127.0.0.1:$port/payload.txt")
[[ "$code" == "200" ]] || {
    printf 'expected 200, got %q\n' "$code" >&2
    exit 1
}
diff -q "$tmpdir/srv/payload.txt" "$tmpdir/got.txt"
