#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-r10-sel-normalize-space
# @title: xmlstarlet sel normalize-space collapses whitespace
# @description: Applies XPath normalize-space() to a text node padded with leading, trailing, and interior whitespace, and asserts the printed value has whitespace collapsed to single spaces with edges trimmed.
# @timeout: 60
# @tags: usage, xmlstarlet, xpath
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.xml" <<'XML'
<root>
  <msg>   alpha    beta   gamma   </msg>
</root>
XML

xmlstarlet sel -t -v 'normalize-space(/root/msg)' "$tmpdir/in.xml" >"$tmpdir/out"
value=$(cat "$tmpdir/out")
[[ "$value" == "alpha beta gamma" ]] || {
  echo "expected 'alpha beta gamma', got: '$value'" >&2
  exit 1
}
