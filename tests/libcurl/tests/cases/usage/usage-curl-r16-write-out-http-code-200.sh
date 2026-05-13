#!/usr/bin/env bash
# @testcase: usage-curl-r16-write-out-http-code-200
# @title: curl --write-out %{http_code} prints 200 for a successful loopback GET
# @description: Hosts a small payload on a loopback http.server and asserts curl with -w "%{http_code}" emits literally "200" to stdout on a successful GET, locking in the http_code write-out token shape against a known-good endpoint.
# @timeout: 60
# @tags: usage, curl, write-out, http-code
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
printf 'r16 http-code body\n' >"$tmpdir/srv/index.html"

port=$((23200 + RANDOM % 19000))
( cd "$tmpdir/srv" && exec python3 -m http.server "$port" --bind 127.0.0.1 >/dev/null 2>&1 ) &
pid=$!
for _ in $(seq 1 60); do
    curl --noproxy '*' -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/" 2>/dev/null && break
    sleep 0.1
done

code=$(curl --noproxy '*' -s --max-time 5 -o /dev/null \
    -w '%{http_code}' "http://127.0.0.1:$port/index.html")
[[ "$code" == "200" ]] || {
    printf 'expected 200, got %s\n' "$code" >&2
    exit 1
}
