#!/usr/bin/env bash
# @testcase: usage-curl-writeout-time-fields
# @title: curl write-out time variables
# @description: Uses curl -w to print %{time_total}, %{time_namelookup}, and %{time_connect} for a loopback fetch and verifies all three are present and parseable as non-negative floating point values.
# @timeout: 180
# @tags: usage, curl, http
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-writeout-time-fields"
tmpdir=$(mktemp -d)
trap 'jobs -pr | xargs -r kill 2>/dev/null || true; rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/www"
printf 'time field body\n' >"$tmpdir/www/index.txt"

port=$((29000 + RANDOM % 10000))
python3 -m http.server "$port" --bind 127.0.0.1 --directory "$tmpdir/www" >"$tmpdir/http.log" 2>&1 &
for _ in $(seq 1 50); do
  curl -fsS "http://127.0.0.1:$port/index.txt" >/dev/null 2>&1 && break
  sleep 0.1
done

curl -fsS -o /dev/null \
  -w 'tt=%{time_total}\ntn=%{time_namelookup}\ntc=%{time_connect}\n' \
  "http://127.0.0.1:$port/index.txt" >"$tmpdir/out"

python3 - "$tmpdir/out" <<'PY'
import re, sys
text = open(sys.argv[1]).read()
fields = dict(re.findall(r'^(\w+)=([0-9.eE+-]+)', text, re.M))
for key in ('tt', 'tn', 'tc'):
    assert key in fields, (key, text)
    val = float(fields[key].replace(',', '.'))
    assert val >= 0, (key, val)
PY
