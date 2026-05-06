#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-r10-sel-copy-of-subtree
# @title: xmlstarlet sel -c copies a matched subtree to output
# @description: Selects with -c (copy) on a single subtree and asserts the emitted XML preserves the element name plus its inner content from the source document.
# @timeout: 60
# @tags: usage, xmlstarlet, xpath
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.xml" <<'XML'
<root>
  <node id="x">
    <a>1</a>
    <b>2</b>
  </node>
  <ignored/>
</root>
XML

xmlstarlet sel -t -c '/root/node' "$tmpdir/in.xml" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" '<node id="x">'
validator_assert_contains "$tmpdir/out" '<a>1</a>'
validator_assert_contains "$tmpdir/out" '<b>2</b>'
grep -q 'ignored' "$tmpdir/out" && {
  echo "ignored element should not have been copied" >&2
  cat "$tmpdir/out" >&2
  exit 1
}
exit 0
