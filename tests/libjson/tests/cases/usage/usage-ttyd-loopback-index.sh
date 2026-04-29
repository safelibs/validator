#!/usr/bin/env bash
# @testcase: usage-ttyd-loopback-index
# @title: ttyd loopback web session
# @description: Starts ttyd on loopback and requests its web page to exercise json-c through a service-style client.
# @timeout: 180
# @tags: usage, service, json
# @client: ttyd

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    port=17681
ttyd -i 127.0.0.1 -p "$port" bash -lc 'printf validator-ttyd' >"$tmpdir/ttyd.log" 2>&1 &
pid=$!
trap 'kill "$pid" 2>/dev/null || true; rm -rf "$tmpdir"' EXIT
for _ in $(seq 1 40); do curl -fsS "http://127.0.0.1:$port/" >"$tmpdir/page.html" 2>"$tmpdir/curl.err" && break || sleep 0.25; done
validator_require_file "$tmpdir/page.html"
validator_assert_contains "$tmpdir/page.html" 'ttyd'
kill "$pid" 2>/dev/null || true
wait "$pid" 2>/dev/null || true
