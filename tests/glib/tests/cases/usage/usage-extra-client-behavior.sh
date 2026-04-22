#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
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

case "$case_id" in
  usage-gio-move-file)
    printf 'move payload\n' >"$tmpdir/input.txt"
    gio move "$tmpdir/input.txt" "$tmpdir/output.txt"
    test ! -e "$tmpdir/input.txt"
    validator_assert_contains "$tmpdir/output.txt" 'move payload'
    ;;
  usage-gio-list-directory)
    mkdir -p "$tmpdir/tree"
    printf 'alpha\n' >"$tmpdir/tree/alpha.txt"
    printf 'beta\n' >"$tmpdir/tree/beta.txt"
    gio list "$tmpdir/tree" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'alpha.txt'
    validator_assert_contains "$tmpdir/out" 'beta.txt'
    ;;
  usage-gio-info-size)
    printf '1234567890' >"$tmpdir/input.txt"
    gio info -a standard::size "$tmpdir/input.txt" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '10'
    ;;
  usage-glib-compile-resources)
    mkdir -p "$tmpdir/res"
    printf 'resource payload\n' >"$tmpdir/res/payload.txt"
    cat >"$tmpdir/res/demo.gresource.xml" <<'XML'
<gresources>
  <gresource prefix="/org/validator">
    <file>payload.txt</file>
  </gresource>
</gresources>
XML
    glib-compile-resources --sourcedir="$tmpdir/res" --target="$tmpdir/demo.gresource" "$tmpdir/res/demo.gresource.xml"
    validator_require_file "$tmpdir/demo.gresource"
    test "$(wc -c <"$tmpdir/demo.gresource")" -gt 0
    ;;
  usage-glib-compile-schemas-boolean)
    write_bool_schema
    glib-compile-schemas "$tmpdir/schemas"
    GSETTINGS_SCHEMA_DIR="$tmpdir/schemas" gsettings get org.validator.extra enabled | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'true'
    ;;
  usage-python3-gi-checksum)
    python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
checksum = GLib.Checksum.new(GLib.ChecksumType.SHA256)
checksum.update(b"payload")
print(checksum.get_string())
PY
    validator_assert_contains "$tmpdir/out" '239f59ed'
    ;;
  usage-python3-gi-uri-escape)
    python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
escaped = GLib.uri_escape_string("hello world/value", None, False)
print(escaped)
print(GLib.uri_unescape_string(escaped, None))
PY
    validator_assert_contains "$tmpdir/out" 'hello%20world%2Fvalue'
    validator_assert_contains "$tmpdir/out" 'hello world/value'
    ;;
  usage-python3-gi-bytes)
    python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
payload = GLib.Bytes.new(b"bytes payload")
print(payload.get_size())
print(payload.get_data().decode())
PY
    validator_assert_contains "$tmpdir/out" 'bytes payload'
    ;;
  usage-python3-gi-memory-stream)
    python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib, Gio
payload = GLib.Bytes.new(b"stream payload")
stream = Gio.MemoryInputStream.new_from_bytes(payload)
chunk = stream.read_bytes(64, None)
print(chunk.get_data().decode())
PY
    validator_assert_contains "$tmpdir/out" 'stream payload'
    ;;
  usage-python3-gi-idle-callback)
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
    ;;
  *)
    printf 'unknown glib extra usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
