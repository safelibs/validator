#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-sel-template-multi
# @title: xmlstarlet sel template multi-element
# @description: Uses xmlstarlet sel -t -m to iterate over multiple matching elements and emit one record per match, verifying the exact joined output and the total record count.
# @timeout: 180
# @tags: usage, xml, cli
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-xmlstarlet-sel-template-multi"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.xml" <<'XML'
<root>
  <item id="a" weight="2">alpha</item>
  <item id="b" weight="3">beta</item>
  <item id="c" weight="5">gamma</item>
</root>
XML

xmlstarlet sel -t \
  -m '/root/item' \
    -v '@id' -o '=' -v '.' -o ':' -v '@weight' -n \
  "$tmpdir/in.xml" >"$tmpdir/out"

count=$(grep -c '=' "$tmpdir/out" || true)
[[ "$count" == "3" ]] || {
  printf 'expected 3 records, got %s\n' "$count" >&2
  cat "$tmpdir/out" >&2
  exit 1
}

# Exact line content for each record.
grep -Fxq 'a=alpha:2' "$tmpdir/out" || { sed -n '1,20p' "$tmpdir/out" >&2; exit 1; }
grep -Fxq 'b=beta:3'  "$tmpdir/out" || { sed -n '1,20p' "$tmpdir/out" >&2; exit 1; }
grep -Fxq 'c=gamma:5' "$tmpdir/out" || { sed -n '1,20p' "$tmpdir/out" >&2; exit 1; }
