#!/usr/bin/env bash
# @testcase: usage-python3-gi-uri-parse
# @title: PyGObject URI parse
# @description: Parses a URI through GLib in PyGObject and verifies the scheme, host, and path components.
# @timeout: 180
# @tags: usage, glib, python
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-uri-parse"
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
uri = GLib.Uri.parse("https://example.invalid/demo/path?name=alpha", GLib.UriFlags.NONE)
print(uri.get_scheme())
print(uri.get_host())
print(uri.get_path())
PY
validator_assert_contains "$tmpdir/out" 'https'
validator_assert_contains "$tmpdir/out" 'example.invalid'
validator_assert_contains "$tmpdir/out" '/demo/path'
