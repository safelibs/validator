#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

case "$case_id" in
  usage-gio-copy-local-file-batch11)
    printf 'gio copy payload\n' >"$tmpdir/source.txt"
    gio copy "$tmpdir/source.txt" "$tmpdir/copied.txt"
    validator_assert_contains "$tmpdir/copied.txt" 'gio copy payload'
    ;;
  usage-gio-mkdir-list-batch11)
    gio mkdir "$tmpdir/gio-dir"
    printf 'listed\n' >"$tmpdir/gio-dir/item.txt"
    gio list "$tmpdir/gio-dir" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'item.txt'
    ;;
  usage-gio-info-size-batch11)
    printf '12345' >"$tmpdir/sized.txt"
    gio info -a standard::size "$tmpdir/sized.txt" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'standard::size: 5'
    ;;
  usage-python3-gi-path-basename-batch11)
    python3 >"$tmpdir/out" <<'PYCASE'
from gi.repository import GLib
print(GLib.path_get_basename('/tmp/validator/file.txt'))
PYCASE
    validator_assert_contains "$tmpdir/out" 'file.txt'
    ;;
  usage-python3-gi-shell-quote-batch11)
    python3 >"$tmpdir/out" <<'PYCASE'
from gi.repository import GLib
print(GLib.shell_quote('alpha beta'))
PYCASE
    validator_assert_contains "$tmpdir/out" "'alpha beta'"
    ;;
  usage-python3-gi-markup-escape-batch11)
    python3 >"$tmpdir/out" <<'PYCASE'
from gi.repository import GLib
print(GLib.markup_escape_text('<tag>&value'))
PYCASE
    validator_assert_contains "$tmpdir/out" '&lt;tag&gt;&amp;value'
    ;;
  usage-python3-gi-uri-unescape-batch11)
    python3 >"$tmpdir/out" <<'PYCASE'
from gi.repository import GLib
print(GLib.uri_unescape_string('alpha%20beta', None))
PYCASE
    validator_assert_contains "$tmpdir/out" 'alpha beta'
    ;;
  usage-python3-gi-uuid-random-batch11)
    python3 >"$tmpdir/out" <<'PYCASE'
from gi.repository import GLib
value = GLib.uuid_string_random()
assert len(value) == 36 and value.count('-') == 4
print(value)
PYCASE
    test "$(wc -c <"$tmpdir/out")" -gt 30
    ;;
  usage-python3-gi-variant-int-array-batch11)
    python3 >"$tmpdir/out" <<'PYCASE'
from gi.repository import GLib
value = GLib.Variant('ai', [3, 5, 8])
print(value.n_children())
print(value.get_child_value(2).get_int32())
PYCASE
    validator_assert_contains "$tmpdir/out" '3'
    validator_assert_contains "$tmpdir/out" '8'
    ;;
  usage-python3-gi-unix-epoch-year-batch11)
    python3 >"$tmpdir/out" <<'PYCASE'
from gi.repository import GLib
dt = GLib.DateTime.new_from_unix_utc(0)
print(dt.format('%Y-%m-%d'))
PYCASE
    validator_assert_contains "$tmpdir/out" '1970-01-01'
    ;;
  *)
    printf 'unknown glib eleventh-batch usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
