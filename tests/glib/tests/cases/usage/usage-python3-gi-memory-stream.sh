#!/usr/bin/env bash
# @testcase: usage-python3-gi-memory-stream
# @title: PyGObject memory stream
# @description: Reads bytes from a Gio memory input stream through PyGObject.
# @timeout: 180
# @tags: usage, gio, python
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-memory-stream"
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
from gi.repository import GLib, Gio
payload = GLib.Bytes.new(b"stream payload")
stream = Gio.MemoryInputStream.new_from_bytes(payload)
chunk = stream.read_bytes(64, None)
print(chunk.get_data().decode())
PY
validator_assert_contains "$tmpdir/out" 'stream payload'
