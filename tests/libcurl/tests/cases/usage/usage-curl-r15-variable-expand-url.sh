#!/usr/bin/env bash
# @testcase: usage-curl-r15-variable-expand-url
# @title: curl --variable + --expand-url substitutes a variable into the request URL at fetch time
# @description: Defines a curl variable HOST=127.0.0.1 with --variable, then issues a request whose URL contains "{{HOST}}" with --expand-url. Asserts curl substitutes the variable into the URL at request time and the loopback server delivers the expected body.
# @timeout: 180
# @tags: usage, curl, http, variable, expand-url
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
printf 'r15 expand-url body\n' >"$tmpdir/srv/payload.txt"
port=$((23000 + RANDOM % 19000))
( cd "$tmpdir/srv" && exec python3 -m http.server "$port" >/dev/null 2>&1 ) &
pid=$!
for _ in $(seq 1 60); do
    curl --noproxy '*' -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/" 2>/dev/null && break
    sleep 0.1
done

curl --noproxy '*' -fsS --max-time 5 \
    --variable "HOST=127.0.0.1" \
    --expand-url "http://{{HOST}}:$port/payload.txt" \
    -o "$tmpdir/got.txt"

diff -q "$tmpdir/srv/payload.txt" "$tmpdir/got.txt"
