#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-sel-build-element
# @title: xmlstarlet sel template build element
# @description: Uses xmlstarlet sel -t with nested -e directives to construct a synthetic XML element wrapping a child element per matched node, and verifies the resulting structure has exactly one wrapper element with the expected child count and per-record attribute bindings.
# @timeout: 180
# @tags: usage, xml, cli
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

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
  -e 'records' \
    -m '/root/item' \
      -e 'record' \
        -a 'id' -v '@id' -b \
        -a 'name' -v '.' -b \
      -b \
  "$tmpdir/in.xml" >"$tmpdir/out"

# Wrapper must appear exactly once. xmlstarlet sel emits the result on a
# single line, so count occurrences with grep -o, not matching lines.
wrap=$(grep -o '<records' "$tmpdir/out" | wc -l)
[[ "$wrap" == "1" ]] || {
  printf 'expected one <records> wrapper, got %s\n' "$wrap" >&2
  cat "$tmpdir/out" >&2
  exit 1
}

# Three child <record> elements with the expected attribute bindings.
records=$(grep -o '<record ' "$tmpdir/out" | wc -l)
[[ "$records" == "3" ]] || {
  printf 'expected 3 <record> elements, got %s\n' "$records" >&2
  cat "$tmpdir/out" >&2
  exit 1
}

# Each record carries id and name attributes derived from the source.
xmlstarlet sel -t -m '/records/record' -v '@id' -o '=' -v '@name' -n \
  "$tmpdir/out" >"$tmpdir/seq"

grep -Fxq 'a=alpha' "$tmpdir/seq" || { sed -n '1,40p' "$tmpdir/seq" >&2; exit 1; }
grep -Fxq 'b=beta'  "$tmpdir/seq" || { sed -n '1,40p' "$tmpdir/seq" >&2; exit 1; }
grep -Fxq 'c=gamma' "$tmpdir/seq" || { sed -n '1,40p' "$tmpdir/seq" >&2; exit 1; }
