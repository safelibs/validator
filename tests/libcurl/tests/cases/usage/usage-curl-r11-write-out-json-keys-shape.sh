#!/usr/bin/env bash
# @testcase: usage-curl-r11-write-out-json-keys-shape
# @title: curl --write-out '%{json}' emits a JSON object with documented keys
# @description: Hits a loopback HTTP server with -w '%{json}' and asserts the captured payload parses as a JSON object containing http_code, method, scheme, response_code and exitcode keys.
# @timeout: 180
# @tags: usage, curl, http, write-out, json
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
printf 'json-shape-target\n' >"$tmpdir/srv/index.html"
port=$((28700 + RANDOM % 8000))
( cd "$tmpdir/srv" && python3 -m http.server "$port" >/dev/null 2>&1 ) &
pid=$!
for _ in $(seq 1 50); do
  curl -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/" 2>/dev/null && break
  sleep 0.1
done

curl -sS --max-time 5 -o /dev/null -w '%{json}' "http://127.0.0.1:$port/" >"$tmpdir/out.json"
python3 - "$tmpdir/out.json" <<'PY'
import json, sys
with open(sys.argv[1], 'rb') as f:
    j = json.load(f)
required = {'http_code', 'method', 'scheme', 'response_code', 'exitcode'}
missing = required - set(j.keys())
if missing:
    sys.exit(f"%{{json}} missing required keys: {sorted(missing)}")
if j.get('http_code') != 200 or j.get('response_code') != 200:
    sys.exit(f"unexpected http_code/response_code in %{{json}}: {j.get('http_code')!r}/{j.get('response_code')!r}")
if j.get('method') != 'GET':
    sys.exit(f"unexpected method in %{{json}}: {j.get('method')!r}")
PY
