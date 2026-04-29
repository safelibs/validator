#!/usr/bin/env bash
# @testcase: usage-python3-gi-data-input-stream-line
# @title: PyGObject Gio data input stream
# @description: Reads the first line of a file through Gio.DataInputStream in PyGObject.
# @timeout: 180
# @tags: usage, python, gio
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-data-input-stream-line"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

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
