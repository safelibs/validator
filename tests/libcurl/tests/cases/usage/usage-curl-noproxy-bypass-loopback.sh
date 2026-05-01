#!/usr/bin/env bash
# @testcase: usage-curl-noproxy-bypass-loopback
# @title: curl --noproxy bypasses --proxy for matched host
# @description: Configures an unreachable proxy with --proxy plus --noproxy 127.0.0.1, then fetches from a loopback http.server. The request must reach the loopback server directly because the --noproxy match disables the proxy for that host.
# @timeout: 180
# @tags: usage, curl, http, proxy
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-noproxy-bypass-loopback"
tmpdir=$(mktemp -d)
pid=""
cleanup() {
  if [[ -n "$pid" ]]; then
    kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
  fi
  rm -rf "$tmpdir"
}
trap cleanup EXIT

mkdir -p "$tmpdir/www"
printf 'noproxy bypass body\n' >"$tmpdir/www/file.txt"
port=$((29000 + RANDOM % 10000))
python3 -m http.server "$port" --bind 127.0.0.1 --directory "$tmpdir/www" >"$tmpdir/http.log" 2>&1 &
pid=$!
for _ in $(seq 1 50); do
  if curl -fsS "http://127.0.0.1:$port/file.txt" >/dev/null 2>&1; then
    break
  fi
  sleep 0.1
done

curl --noproxy '127.0.0.1' --proxy 'http://127.0.0.1:1' \
  -fsS "http://127.0.0.1:$port/file.txt" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'noproxy bypass body'
