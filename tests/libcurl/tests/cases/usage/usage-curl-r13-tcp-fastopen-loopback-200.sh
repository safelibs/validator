#!/usr/bin/env bash
# @testcase: usage-curl-r13-tcp-fastopen-loopback-200
# @title: curl --tcp-fastopen completes a loopback GET with 200 OK
# @description: Starts a python loopback HTTP server, fetches a small file with curl --tcp-fastopen, asserts the response code is 200 and the body matches the on-disk file byte-for-byte. The kernel may not honor TFO inside the harness, but curl must accept the option and still complete the transfer.
# @timeout: 180
# @tags: usage, curl, http, tcp
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
printf 'r13 tcp-fastopen body\n' >"$tmpdir/srv/payload.txt"
port=$((23000 + RANDOM % 19000))
( cd "$tmpdir/srv" && python3 -m http.server "$port" >/dev/null 2>&1 ) &
pid=$!
for _ in $(seq 1 60); do
    curl --noproxy '*' -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/" 2>/dev/null && break
    sleep 0.1
done

code=$(curl --noproxy '*' -sS --max-time 5 --tcp-fastopen \
    -o "$tmpdir/got.txt" -w '%{http_code}' "http://127.0.0.1:$port/payload.txt")
[[ "$code" == "200" ]] || {
    printf 'expected 200, got %q\n' "$code" >&2
    exit 1
}
diff -q "$tmpdir/srv/payload.txt" "$tmpdir/got.txt"
