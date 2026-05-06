#!/usr/bin/env bash
# @testcase: usage-curl-r11-noproxy-bypasses-env-proxy
# @title: curl --noproxy bypasses an unreachable HTTP_PROXY environment variable
# @description: Sets HTTP_PROXY to an unreachable address and verifies that --noproxy 127.0.0.1 still allows curl to talk directly to a loopback server, returning HTTP 200.
# @timeout: 180
# @tags: usage, curl, http, proxy
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
printf 'noproxy-target\n' >"$tmpdir/srv/index.html"
port=$((29100 + RANDOM % 8000))
( cd "$tmpdir/srv" && python3 -m http.server "$port" >/dev/null 2>&1 ) &
pid=$!
for _ in $(seq 1 50); do
  curl -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/" 2>/dev/null && break
  sleep 0.1
done

code=$(HTTP_PROXY=http://10.255.255.1:9 \
       https_proxy=http://10.255.255.1:9 \
       curl -sS --max-time 5 --noproxy 127.0.0.1 \
            -o /dev/null -w '%{response_code}' \
            "http://127.0.0.1:$port/")
[[ "$code" == "200" ]] || {
  printf 'expected response_code 200 with --noproxy, got %q\n' "$code" >&2
  exit 1
}
