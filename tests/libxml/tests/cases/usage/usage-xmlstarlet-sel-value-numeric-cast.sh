#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-sel-value-numeric-cast
# @title: xmlstarlet select numeric cast
# @description: Uses xmlstarlet sel -t -v with the XPath number() function to coerce attribute strings to numbers, computes a sum of weight attributes through sum() and number() in separate templates, and verifies both the cast scalar values and the aggregate result.
# @timeout: 180
# @tags: usage, xml, cli, xpath
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-xmlstarlet-sel-value-numeric-cast"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

xml="$tmpdir/in.xml"
cat >"$xml" <<'XML'
<root>
  <item id="a" weight="2"/>
  <item id="b" weight="3"/>
  <item id="c" weight="5"/>
  <item id="d" weight="7"/>
</root>
XML

xmlstarlet sel -t -v 'number(/root/item[@id="b"]/@weight) + 10' -n "$xml" >"$tmpdir/num.txt"
xmlstarlet sel -t -v 'sum(/root/item/@weight)' -n "$xml" >"$tmpdir/sum.txt"
xmlstarlet sel -t -v 'count(/root/item)' -n "$xml" >"$tmpdir/count.txt"

num_val=$(tr -d '[:space:]' <"$tmpdir/num.txt")
sum_val=$(tr -d '[:space:]' <"$tmpdir/sum.txt")
count_val=$(tr -d '[:space:]' <"$tmpdir/count.txt")

[[ "$num_val" == "13" ]] || {
  printf 'expected number() cast result 13, got %s\n' "$num_val" >&2
  exit 1
}
[[ "$sum_val" == "17" ]] || {
  printf 'expected weight sum 17, got %s\n' "$sum_val" >&2
  exit 1
}
[[ "$count_val" == "4" ]] || {
  printf 'expected item count 4, got %s\n' "$count_val" >&2
  exit 1
}

printf 'num=%s\nsum=%s\ncount=%s\n' "$num_val" "$sum_val" "$count_val"
