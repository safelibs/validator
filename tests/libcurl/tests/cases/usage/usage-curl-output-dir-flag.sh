#!/usr/bin/env bash
# @testcase: usage-curl-output-dir-flag
# @title: curl --output-dir writes to nested directory
# @description: Combines curl --output-dir, --create-dirs and --remote-name to download a loopback URL into a freshly-created nested directory and verifies the file landed there.
# @timeout: 180
# @tags: usage, curl, http
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-output-dir-flag"
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
printf 'output-dir payload\n' >"$tmpdir/www/payload.txt"
port=$((29000 + RANDOM % 10000))
python3 -m http.server "$port" --bind 127.0.0.1 --directory "$tmpdir/www" >"$tmpdir/http.log" 2>&1 &
pid=$!
for _ in $(seq 1 50); do
  if curl -fsS "http://127.0.0.1:$port/payload.txt" >/dev/null 2>&1; then
    break
  fi
  sleep 0.1
done

dest="$tmpdir/dest/nested/sub"
[[ ! -d "$dest" ]]
( cd "$tmpdir" && curl -fsS --create-dirs --output-dir "$dest" -O "http://127.0.0.1:$port/payload.txt" )

validator_require_file "$dest/payload.txt"
validator_assert_contains "$dest/payload.txt" 'output-dir payload'
