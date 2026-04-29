#!/usr/bin/env bash
# @testcase: usage-python3-gi-idle-callback
# @title: PyGObject idle callback
# @description: Runs a GLib main loop until an idle callback updates state and quits.
# @timeout: 180
# @tags: usage, glib, python
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-idle-callback"
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
loop = GLib.MainLoop()
state = {"done": False}
def callback():
    state["done"] = True
    loop.quit()
    return GLib.SOURCE_REMOVE
GLib.idle_add(callback)
loop.run()
print("done=%s" % state["done"])
PY
validator_assert_contains "$tmpdir/out" 'done=True'
