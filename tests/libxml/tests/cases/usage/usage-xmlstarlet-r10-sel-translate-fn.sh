#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-r10-sel-translate-fn
# @title: xmlstarlet sel uses XPath translate to uppercase ASCII text
# @description: Applies the classic translate() ASCII-uppercase trick to a known mixed-case text value and asserts the output equals the all-uppercase form.
# @timeout: 60
# @tags: usage, xmlstarlet, xpath
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.xml" <<'XML'
<root>
  <name>HelloWorld</name>
</root>
XML

xmlstarlet sel -t -v "translate(/root/name, 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')" "$tmpdir/in.xml" >"$tmpdir/out"
value=$(cat "$tmpdir/out")
[[ "$value" == "HELLOWORLD" ]] || {
  echo "expected HELLOWORLD, got: $value" >&2
  exit 1
}
