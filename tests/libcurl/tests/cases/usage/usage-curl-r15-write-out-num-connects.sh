#!/usr/bin/env bash
# @testcase: usage-curl-r15-write-out-num-connects
# @title: curl --write-out '%{num_connects}' reports a single TCP connection for one HTTP fetch
# @description: Runs a single curl GET against a loopback HTTP server with --write-out '%{num_connects}\n' and asserts the captured value is exactly "1", pinning the per-transfer connection-count writeout token's behavior for a one-hop request.
# @timeout: 180
# @tags: usage, curl, http, write-out, num-connects
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
printf 'r15 num_connects body\n' >"$tmpdir/srv/payload.txt"
port=$((23000 + RANDOM % 19000))
( cd "$tmpdir/srv" && exec python3 -m http.server "$port" >/dev/null 2>&1 ) &
pid=$!
for _ in $(seq 1 60); do
    curl --noproxy '*' -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/" 2>/dev/null && break
    sleep 0.1
done

n=$(curl --noproxy '*' -fsS --max-time 5 \
    -o /dev/null -w '%{num_connects}' \
    "http://127.0.0.1:$port/payload.txt")
[[ "$n" == "1" ]] || {
    printf 'expected num_connects=1, got %q\n' "$n" >&2
    exit 1
}
