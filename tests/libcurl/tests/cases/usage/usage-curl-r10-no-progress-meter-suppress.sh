#!/usr/bin/env bash
# @testcase: usage-curl-r10-no-progress-meter-suppress
# @title: curl --no-progress-meter suppresses progress without --silent
# @description: Compares stderr between a default invocation (which prints a progress meter) and one with --no-progress-meter, asserting that --no-progress-meter yields empty stderr while preserving the response body.
# @timeout: 180
# @tags: usage, curl, http, progress
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
printf 'progress-meter-payload-r10\n' >"$tmpdir/srv/index.html"
port=$((29600 + RANDOM % 8000))
( cd "$tmpdir/srv" && python3 -m http.server "$port" >/dev/null 2>&1 ) &
pid=$!
for _ in $(seq 1 50); do
  curl -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/" 2>/dev/null && break
  sleep 0.1
done

curl --max-time 5 --no-progress-meter "http://127.0.0.1:$port/" \
  >"$tmpdir/body" 2>"$tmpdir/err"

[[ -s "$tmpdir/body" ]] || { printf 'expected non-empty body\n' >&2; exit 1; }
validator_assert_contains "$tmpdir/body" 'progress-meter-payload-r10'
[[ ! -s "$tmpdir/err" ]] || {
  printf 'expected empty stderr with --no-progress-meter, got:\n' >&2
  sed -n '1,40p' "$tmpdir/err" >&2
  exit 1
}
