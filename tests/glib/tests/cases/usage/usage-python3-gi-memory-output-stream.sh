#!/usr/bin/env bash
# @testcase: usage-python3-gi-memory-output-stream
# @title: PyGObject memory output stream
# @description: Writes bytes into a Gio memory output stream through PyGObject and verifies the captured payload.
# @timeout: 180
# @tags: usage, glib, python
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-memory-output-stream"
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
from gi.repository import GLib, Gio
stream = Gio.MemoryOutputStream.new_resizable()
stream.write_bytes(GLib.Bytes.new(b"memory output"), None)
stream.close(None)
payload = stream.steal_as_bytes().get_data().decode()
print(payload)
PY
validator_assert_contains "$tmpdir/out" 'memory output'
