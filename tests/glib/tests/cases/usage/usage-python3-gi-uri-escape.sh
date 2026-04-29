#!/usr/bin/env bash
# @testcase: usage-python3-gi-uri-escape
# @title: PyGObject URI escaping
# @description: Escapes and unescapes a string through GLib URI helpers from PyGObject.
# @timeout: 180
# @tags: usage, glib, python
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-uri-escape"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

write_bool_schema() {
  mkdir -p "$tmpdir/schemas"
  cat >"$tmpdir/schemas/org.validator.extra.gschema.xml" <<'XML'
<schemalist>
  <schema id="org.validator.extra" path="/org/validator/extra/">
    <key name="enabled" type="b">
      <default>true</default>
    </key>
  </schema>
</schemalist>
XML
}

write_string_schema() {
  mkdir -p "$tmpdir/schemas-string"
  cat >"$tmpdir/schemas-string/org.validator.extra-string.gschema.xml" <<'XML'
<schemalist>
  <schema id="org.validator.extra-string" path="/org/validator/extra-string/">
    <key name="label" type="s">
      <default>'alpha'</default>
    </key>
  </schema>
</schemalist>
XML
}

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
escaped = GLib.uri_escape_string("hello world/value", None, False)
print(escaped)
print(GLib.uri_unescape_string(escaped, None))
PY
validator_assert_contains "$tmpdir/out" 'hello%20world%2Fvalue'
validator_assert_contains "$tmpdir/out" 'hello world/value'
