#!/usr/bin/env bash
# @testcase: usage-ttyd-r11-loopback-base-path-prefix
# @title: ttyd -b /xterm mounts the index page only under the configured prefix
# @description: Starts ttyd on loopback with a /xterm base-path and verifies the index page (json-c served) returns 200 at /xterm/ while the bare / responds 404, exercising the reverse-proxy mount path.
# @timeout: 180
# @tags: usage, ttyd, json, base-path
# @client: ttyd

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

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

port=$((28000 + RANDOM % 3000))
ttyd -i 127.0.0.1 -p "$port" -b /xterm bash -lc 'printf hi' \
  >"$tmpdir/ttyd.log" 2>&1 &
pid=$!

ready=0
for _ in $(seq 1 40); do
  status=$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:$port/xterm/" || true)
  if [[ "$status" == "200" ]]; then
    ready=1
    break
  fi
  sleep 0.25
done

if (( ready == 0 )); then
  sed -n '1,120p' "$tmpdir/ttyd.log" >&2 || true
  exit 1
fi

bare=$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:$port/" || true)
[[ "$bare" == "404" ]]
