#!/usr/bin/env bash
# @testcase: usage-python3-gi-r12-gio-file-load-contents-roundtrip
# @title: PyGObject Gio.File.new_for_path load_contents reads back UTF-8 payload
# @description: Writes a UTF-8 file on disk, opens it via Gio.File.new_for_path, calls load_contents, and asserts the returned bytes decode to the original string.
# @timeout: 60
# @tags: usage, python, gio, file
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'r12-payload-\xc3\xa9\n' >"$tmpdir/in.txt"

python3 - "$tmpdir/in.txt" >"$tmpdir/out" <<'PY'
import sys
from gi.repository import Gio
path = sys.argv[1]
gfile = Gio.File.new_for_path(path)
ok, contents, _etag = gfile.load_contents(None)
print("ok", ok)
print("type", type(contents).__name__)
print("decoded", bytes(contents).decode("utf-8").rstrip("\n"))
PY

validator_assert_contains "$tmpdir/out" 'ok True'
validator_assert_contains "$tmpdir/out" 'decoded r12-payload-é'
