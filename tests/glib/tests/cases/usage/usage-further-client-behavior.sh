#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

case "$case_id" in
  usage-gio-save-stdin-file)
    printf 'saved through gio\n' | gio save "$tmpdir/out.txt"
    validator_assert_contains "$tmpdir/out.txt" 'saved through gio'
    ;;
  usage-python3-gi-regex-match)
    python3 >"$tmpdir/out" <<'PYCASE'
from gi.repository import GLib
print(f"match={GLib.regex_match_simple('beta', 'alpha beta gamma', 0, 0)}")
PYCASE
    validator_assert_contains "$tmpdir/out" 'match=True'
    ;;
  usage-python3-gi-keyfile-integer-list)
    python3 >"$tmpdir/out" <<'PYCASE'
from gi.repository import GLib
key = GLib.KeyFile()
key.set_integer_list('demo', 'values', [2, 4, 6])
print(','.join(str(value) for value in key.get_integer_list('demo', 'values')))
PYCASE
    validator_assert_contains "$tmpdir/out" '2,4,6'
    ;;
  usage-python3-gi-variant-builder-array)
    python3 >"$tmpdir/out" <<'PYCASE'
from gi.repository import GLib
builder = GLib.VariantBuilder.new(GLib.VariantType.new('as'))
builder.add_value(GLib.Variant('s', 'alpha'))
builder.add_value(GLib.Variant('s', 'beta'))
value = builder.end()
print(','.join(value.unpack()))
PYCASE
    validator_assert_contains "$tmpdir/out" 'alpha,beta'
    ;;
  usage-python3-gi-file-replace-contents)
    INPUT_PATH="$tmpdir/out.txt" python3 >"$tmpdir/out" <<'PYCASE'
import os
from gi.repository import Gio
path = os.environ['INPUT_PATH']
file = Gio.File.new_for_path(path)
file.replace_contents(b'replaced payload\n', None, False, Gio.FileCreateFlags.NONE, None)
ok, contents, _etag = file.load_contents(None)
print(contents.decode('utf-8').strip())
PYCASE
    validator_assert_contains "$tmpdir/out" 'replaced payload'
    ;;
  usage-python3-gi-data-input-stream-line)
    printf 'first line\nsecond line\n' >"$tmpdir/input.txt"
    INPUT_PATH="$tmpdir/input.txt" python3 >"$tmpdir/out" <<'PYCASE'
import os
from gi.repository import Gio
file = Gio.File.new_for_path(os.environ['INPUT_PATH'])
stream = Gio.DataInputStream.new(file.read(None))
line, _length = stream.read_line_utf8(None)
print(line)
stream.close(None)
PYCASE
    validator_assert_contains "$tmpdir/out" 'first line'
    ;;
  usage-python3-gi-markup-escape)
    python3 >"$tmpdir/out" <<'PYCASE'
from gi.repository import GLib
print(GLib.markup_escape_text('<alpha>&'))
PYCASE
    validator_assert_contains "$tmpdir/out" '&lt;alpha&gt;&amp;'
    ;;
  usage-python3-gi-checksum-sha1)
    python3 >"$tmpdir/out" <<'PYCASE'
from gi.repository import GLib
checksum = GLib.Checksum.new(GLib.ChecksumType.SHA1)
checksum.update(b'abc')
print(checksum.get_string())
PYCASE
    validator_assert_contains "$tmpdir/out" 'a9993e364706816aba3e25717850c26c9cd0d89d'
    ;;
  usage-python3-gi-keyfile-groups)
    python3 >"$tmpdir/out" <<'PYCASE'
from gi.repository import GLib
payload = '[first]\na=1\n[second]\nb=2\n'
key = GLib.KeyFile()
key.load_from_data(payload, len(payload), GLib.KeyFileFlags.NONE)
groups, _length = key.get_groups()
print(','.join(groups))
PYCASE
    validator_assert_contains "$tmpdir/out" 'first,second'
    ;;
  usage-python3-gi-variant-lookup)
    python3 >"$tmpdir/out" <<'PYCASE'
from gi.repository import GLib
value = GLib.Variant('a{si}', {'alpha': 1, 'beta': 2})
lookup = value.lookup_value('beta', GLib.VariantType.new('i'))
print(lookup.unpack())
PYCASE
    validator_assert_contains "$tmpdir/out" '2'
    ;;
  *)
    printf 'unknown glib further usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
