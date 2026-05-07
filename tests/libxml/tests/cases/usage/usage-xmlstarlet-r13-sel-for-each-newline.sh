#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-r13-sel-for-each-newline
# @title: xmlstarlet sel -t -m loop -v -n emits one value per line for each match
# @description: Runs xmlstarlet sel with a -m loop over /catalog/item, prints each item text via -v "." and a newline via -n, and asserts the output is exactly four newline-separated values in document order without extra leading or trailing blank lines.
# @timeout: 60
# @tags: usage, xmlstarlet, select, template
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.xml" <<'XML'
<catalog>
  <item>alpha</item>
  <item>bravo</item>
  <item>charlie</item>
  <item>delta</item>
</catalog>
XML

xmlstarlet sel -t -m '/catalog/item' -v '.' -n "$tmpdir/in.xml" >"$tmpdir/out"

# Exactly four lines.
lines=$(wc -l <"$tmpdir/out")
[[ "$lines" == "4" ]] || {
    printf 'expected 4 lines, got %s\n' "$lines" >&2
    cat "$tmpdir/out" >&2
    exit 1
}

# Lines in document order.
[[ "$(sed -n '1p' "$tmpdir/out")" == "alpha" ]]
[[ "$(sed -n '2p' "$tmpdir/out")" == "bravo" ]]
[[ "$(sed -n '3p' "$tmpdir/out")" == "charlie" ]]
[[ "$(sed -n '4p' "$tmpdir/out")" == "delta" ]]
