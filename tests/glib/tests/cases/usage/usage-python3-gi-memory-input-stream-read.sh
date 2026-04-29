#!/usr/bin/env bash
# @testcase: usage-python3-gi-memory-input-stream-read
# @title: PyGObject memory input stream read
# @description: Exercises pygobject memory input stream read through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-memory-input-stream-read"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

write_double_schema() {
  mkdir -p "$tmpdir/schemas-double"
  cat >"$tmpdir/schemas-double/org.validator.double.gschema.xml" <<'XML'
<schemalist>
  <schema id="org.validator.double" path="/org/validator/double/">
    <key name="ratio" type="d">
      <default>2.5</default>
    </key>
  </schema>
</schemalist>
XML
}

write_int_array_schema() {
  mkdir -p "$tmpdir/schemas-array"
  cat >"$tmpdir/schemas-array/org.validator.int-array.gschema.xml" <<'XML'
<schemalist>
  <schema id="org.validator.int-array" path="/org/validator/int-array/">
    <key name="items" type="ai">
      <default>[1, 2, 3]</default>
    </key>
  </schema>
</schemalist>
XML
}

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib, Gio
stream = Gio.MemoryInputStream.new_from_bytes(GLib.Bytes.new(b'memory input payload'))
print(stream.read_bytes(64, None).get_data().decode())
PY
validator_assert_contains "$tmpdir/out" 'memory input payload'
