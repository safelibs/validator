#!/usr/bin/env bash
# @testcase: usage-python3-gi-file-enumerator-names
# @title: PyGObject Gio file enumerator
# @description: Enumerates directory entries through Gio with PyGObject and verifies both filenames are reported.
# @timeout: 180
# @tags: usage, python, gio
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-file-enumerator-names"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

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
