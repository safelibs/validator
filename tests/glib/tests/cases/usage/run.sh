#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
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

case "$case_id" in
  usage-gio-cat-file)
    printf 'gio cat payload\n' >"$tmpdir/input.txt"
    gio cat "$tmpdir/input.txt" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'gio cat payload'
    ;;
  usage-gio-copy-file)
    printf 'gio copy payload\n' >"$tmpdir/input.txt"
    gio copy "$tmpdir/input.txt" "$tmpdir/output.txt"
    validator_assert_contains "$tmpdir/output.txt" 'gio copy payload'
    ;;
  usage-gio-info-file)
    printf 'gio info payload\n' >"$tmpdir/input.txt"
    gio info "$tmpdir/input.txt" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'standard::name'
    ;;
  usage-gio-content-type)
    printf 'content type payload\n' >"$tmpdir/input.txt"
    gio info -a standard::content-type "$tmpdir/input.txt" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'text/plain'
    ;;
  usage-glib-compile-schemas)
    write_schema
    glib-compile-schemas "$tmpdir/schemas"
    validator_require_file "$tmpdir/schemas/gschemas.compiled"
    ;;
  usage-gsettings-read-schema)
    write_schema
    glib-compile-schemas "$tmpdir/schemas"
    GSETTINGS_SCHEMA_DIR="$tmpdir/schemas" gsettings get org.validator.demo message >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'hello-schema'
    ;;
  usage-python3-gi-mainloop)
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
    ;;
  usage-python3-gi-variant)
    python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
value = GLib.Variant("(si)", ("alpha", 7))
print("variant=%s:%d" % value.unpack())
PY
    validator_assert_contains "$tmpdir/out" 'variant=alpha:7'
    ;;
  usage-python3-gi-keyfile)
    python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
key = GLib.KeyFile()
data = "[demo]\nmessage=hello-keyfile\n"
key.load_from_data(data, len(data), GLib.KeyFileFlags.NONE)
print(key.get_string("demo", "message"))
PY
    validator_assert_contains "$tmpdir/out" 'hello-keyfile'
    ;;
  usage-python3-gi-gio-file)
    printf 'pygio payload\n' >"$tmpdir/input.txt"
    INPUT_PATH="$tmpdir/input.txt" python3 >"$tmpdir/out" <<'PY'
import os
from gi.repository import Gio
file = Gio.File.new_for_path(os.environ["INPUT_PATH"])
ok, contents, etag = file.load_contents(None)
print(contents.decode("utf-8").strip())
PY
    validator_assert_contains "$tmpdir/out" 'pygio payload'
    ;;
  *)
    printf 'unknown glib usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
