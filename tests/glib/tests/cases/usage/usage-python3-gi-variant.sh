#!/usr/bin/env bash
# @testcase: usage-python3-gi-variant
# @title: PyGObject GLib Variant
# @description: Creates and unpacks a GLib Variant through the PyGObject binding.
# @timeout: 120
# @tags: usage, python
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-variant"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

write_schema() {
  mkdir -p "$tmpdir/schemas"
  cat >"$tmpdir/schemas/org.validator.demo.gschema.xml" <<'XML'
<schemalist>
  <schema id="org.validator.demo" path="/org/validator/demo/">
    <key name="message" type="s">
      <default>'hello-schema'</default>
    </key>
  </schema>
</schemalist>
XML
}

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
value = GLib.Variant("(si)", ("alpha", 7))
print("variant=%s:%d" % value.unpack())
PY
validator_assert_contains "$tmpdir/out" 'variant=alpha:7'
