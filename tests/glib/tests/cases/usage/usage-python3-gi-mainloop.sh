#!/usr/bin/env bash
# @testcase: usage-python3-gi-mainloop
# @title: PyGObject GLib main loop
# @description: Runs a GLib MainLoop timeout through the PyGObject binding.
# @timeout: 120
# @tags: usage, python
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-mainloop"
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
loop = GLib.MainLoop()
state = {"value": 0}
def tick():
    state["value"] = 42
    loop.quit()
    return GLib.SOURCE_REMOVE
GLib.timeout_add(10, tick)
loop.run()
print(f"value={state['value']}")
PY
validator_assert_contains "$tmpdir/out" 'value=42'
