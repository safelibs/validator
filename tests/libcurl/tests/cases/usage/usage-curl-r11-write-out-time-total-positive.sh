#!/usr/bin/env bash
# @testcase: usage-curl-r11-write-out-time-total-positive
# @title: curl --write-out '%{time_total}' parses as a strictly positive number
# @description: Performs a loopback GET and asserts the %{time_total} write-out token formats as a parseable decimal that is strictly greater than zero.
# @timeout: 180
# @tags: usage, curl, http, write-out, timing
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
printf 'time-total-target\n' >"$tmpdir/srv/index.html"
port=$((28500 + RANDOM % 8000))
( cd "$tmpdir/srv" && python3 -m http.server "$port" >/dev/null 2>&1 ) &
pid=$!
for _ in $(seq 1 50); do
  curl -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/" 2>/dev/null && break
  sleep 0.1
done

t=$(curl -sS --max-time 5 -o /dev/null -w '%{time_total}' "http://127.0.0.1:$port/")
python3 - "$t" <<'PY'
import sys
val = sys.argv[1]
try:
    f = float(val)
except ValueError:
    sys.exit(f"time_total not parseable as float: {val!r}")
if not (f > 0):
    sys.exit(f"expected time_total > 0, got {f!r}")
PY
