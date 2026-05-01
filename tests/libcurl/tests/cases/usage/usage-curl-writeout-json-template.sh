#!/usr/bin/env bash
# @testcase: usage-curl-writeout-json-template
# @title: curl write-out %{json} document
# @description: Uses curl -w '%{json}' to dump the full transfer document and verifies the resulting JSON parses and contains the http_code field for a loopback GET.
# @timeout: 180
# @tags: usage, curl, http
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-writeout-json-template"
tmpdir=$(mktemp -d)
trap 'jobs -pr | xargs -r kill 2>/dev/null || true; rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/www"
printf 'json doc body\n' >"$tmpdir/www/index.txt"

port=$((29000 + RANDOM % 10000))
python3 -m http.server "$port" --bind 127.0.0.1 --directory "$tmpdir/www" >"$tmpdir/http.log" 2>&1 &
for _ in $(seq 1 50); do
  curl -fsS "http://127.0.0.1:$port/index.txt" >/dev/null 2>&1 && break
  sleep 0.1
done

curl -fsS -o /dev/null -w '%{json}\n' "http://127.0.0.1:$port/index.txt" >"$tmpdir/out.json"
python3 -c '
import json, sys
data = json.loads(open(sys.argv[1]).read())
assert data.get("http_code") == 200, data
assert int(data.get("size_download", 0)) > 0, data
' "$tmpdir/out.json"
