#!/usr/bin/env bash
# @testcase: usage-python3-gi-checksum-md5
# @title: PyGObject MD5 checksum
# @description: Computes an MD5 checksum through GLib in PyGObject and verifies the expected digest string.
# @timeout: 180
# @tags: usage, glib, python
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-checksum-md5"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

write_int_schema() {
  mkdir -p "$tmpdir/schemas-int"
  cat >"$tmpdir/schemas-int/org.validator.more-int.gschema.xml" <<'XML'
<schemalist>
  <schema id="org.validator.more-int" path="/org/validator/more-int/">
    <key name="count" type="i">
      <default>7</default>
    </key>
  </schema>
</schemalist>
XML
}

write_array_schema() {
  mkdir -p "$tmpdir/schemas-array"
  cat >"$tmpdir/schemas-array/org.validator.more-array.gschema.xml" <<'XML'
<schemalist>
  <schema id="org.validator.more-array" path="/org/validator/more-array/">
    <key name="items" type="as">
      <default>['alpha', 'beta']</default>
    </key>
  </schema>
</schemalist>
XML
}

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
checksum = GLib.Checksum.new(GLib.ChecksumType.MD5)
checksum.update(b"payload")
print(checksum.get_string())
PY
validator_assert_contains "$tmpdir/out" '321c3cf486ed509164edec1e1981fec8'
