#!/usr/bin/env bash
# @testcase: usage-python3-gi-file-replace-contents
# @title: PyGObject Gio replace contents
# @description: Replaces file contents with Gio.File.replace_contents through PyGObject and reads the new payload back.
# @timeout: 180
# @tags: usage, python, gio
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-file-replace-contents"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

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
