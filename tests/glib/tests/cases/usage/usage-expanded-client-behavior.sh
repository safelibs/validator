#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

case "$case_id" in
  usage-gio-move-file-rename)
    printf 'gio move payload\n' >"$tmpdir/input.txt"
    gio move "$tmpdir/input.txt" "$tmpdir/output.txt"
    validator_assert_contains "$tmpdir/output.txt" 'gio move payload'
    if [[ -e "$tmpdir/input.txt" ]]; then
      printf 'gio move unexpectedly left the source file behind\n' >&2
      exit 1
    fi
    ;;
  usage-gio-list-directory-names)
    mkdir -p "$tmpdir/list"
    printf 'alpha\n' >"$tmpdir/list/a.txt"
    printf 'beta\n' >"$tmpdir/list/b.txt"
    gio list "$tmpdir/list" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'a.txt'
    validator_assert_contains "$tmpdir/out" 'b.txt'
    ;;
  usage-gio-make-directory)
    gio mkdir "$tmpdir/tree"
    test -d "$tmpdir/tree"
    ;;
  usage-python3-gi-bytes-size-payload)
    python3 >"$tmpdir/out" <<'PYCASE'
from gi.repository import GLib
value = GLib.Bytes.new(b'validator-bytes')
print(value.get_size())
PYCASE
    validator_assert_contains "$tmpdir/out" '15'
    ;;
  usage-python3-gi-uri-parse-components)
    python3 >"$tmpdir/out" <<'PYCASE'
from gi.repository import GLib
uri = GLib.Uri.parse('https://example.invalid/path?q=1', GLib.UriFlags.NONE)
print(uri.get_host(), uri.get_path())
PYCASE
    validator_assert_contains "$tmpdir/out" 'example.invalid /path'
    ;;
  usage-python3-gi-checksum-md5-string)
    python3 >"$tmpdir/out" <<'PYCASE'
from gi.repository import GLib
print(GLib.compute_checksum_for_string(GLib.ChecksumType.MD5, 'validator', -1))
PYCASE
    validator_assert_contains "$tmpdir/out" '8d6c391e7cb39133c91b73281a24f21f'
    ;;
  usage-python3-gi-memory-input-stream)
    python3 >"$tmpdir/out" <<'PYCASE'
from gi.repository import Gio
stream = Gio.MemoryInputStream.new_from_data(b'memory-stream', None)
data = stream.read_bytes(13, None)
print(data.get_data().decode('utf-8'))
PYCASE
    validator_assert_contains "$tmpdir/out" 'memory-stream'
    ;;
  usage-python3-gi-file-enumerator-names)
    mkdir -p "$tmpdir/enumerate"
    printf 'left\n' >"$tmpdir/enumerate/a.txt"
    printf 'right\n' >"$tmpdir/enumerate/b.txt"
    ENUM_DIR="$tmpdir/enumerate" python3 >"$tmpdir/out" <<'PYCASE'
import os
from gi.repository import Gio
directory = Gio.File.new_for_path(os.environ['ENUM_DIR'])
enumerator = directory.enumerate_children('standard::name', Gio.FileQueryInfoFlags.NONE, None)
names = []
while True:
    info = enumerator.next_file(None)
    if info is None:
      break
    names.append(info.get_name())
enumerator.close(None)
print(','.join(sorted(names)))
PYCASE
    validator_assert_contains "$tmpdir/out" 'a.txt,b.txt'
    ;;
  usage-python3-gi-idle-add)
    python3 >"$tmpdir/out" <<'PYCASE'
from gi.repository import GLib
loop = GLib.MainLoop()
state = {'value': 0}
def run_once():
    state['value'] = 17
    loop.quit()
    return GLib.SOURCE_REMOVE
GLib.idle_add(run_once)
loop.run()
print(state['value'])
PYCASE
    validator_assert_contains "$tmpdir/out" '17'
    ;;
  usage-python3-gi-variant-dict-count)
    python3 >"$tmpdir/out" <<'PYCASE'
from gi.repository import GLib
dictionary = GLib.VariantDict.new(None)
dictionary.insert_value('count', GLib.Variant('i', 23))
value = dictionary.end()
lookup = value.lookup_value('count', GLib.VariantType.new('i'))
print(lookup.unpack())
PYCASE
    validator_assert_contains "$tmpdir/out" '23'
    ;;
  *)
    printf 'unknown glib expanded usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
