#!/usr/bin/env bash
# @testcase: usage-curl-r12-limit-rate-allows-completion
# @title: curl --limit-rate caps throughput while still completing the transfer with HTTP 200
# @description: Serves a small payload from a loopback http.server, fetches it with curl --limit-rate 1M, and asserts the request completes with response_code 200 and the body matches the served bytes despite the artificial rate cap.
# @timeout: 180
# @tags: usage, curl, http, rate-limit
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
printf 'r12 limit-rate body\n%.0s' {1..32} >"$tmpdir/srv/payload.bin"
cp "$tmpdir/srv/payload.bin" "$tmpdir/expected.bin"

port=$((23000 + RANDOM % 19000))
( cd "$tmpdir/srv" && python3 -m http.server "$port" >/dev/null 2>&1 ) &
pid=$!
for _ in $(seq 1 60); do
    curl --noproxy '*' -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/payload.bin" 2>/dev/null && break
    sleep 0.1
done

code=$(curl --noproxy '*' -sS --max-time 30 --limit-rate 1M \
            -o "$tmpdir/got.bin" -w '%{response_code}' \
            "http://127.0.0.1:$port/payload.bin")
[[ "$code" == "200" ]] || {
    printf 'expected 200 with --limit-rate, got %q\n' "$code" >&2
    exit 1
}
cmp "$tmpdir/got.bin" "$tmpdir/expected.bin"
