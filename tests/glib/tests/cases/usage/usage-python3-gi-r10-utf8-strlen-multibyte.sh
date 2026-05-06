#!/usr/bin/env bash
# @testcase: usage-python3-gi-r10-utf8-strlen-multibyte
# @title: PyGObject GLib.utf8_strlen counts characters not bytes
# @description: Verifies GLib.utf8_strlen returns the unicode character count (5) for a multi-byte UTF-8 string whose byte length (8) is larger.
# @timeout: 60
# @tags: usage, python, utf8
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
text = "café☃"  # 5 unicode chars: c a f é ☃
encoded = text.encode("utf-8")
chars = GLib.utf8_strlen(text, -1)
print("bytes", len(encoded))
print("chars", chars)
assert len(encoded) == 8
assert chars == 5
PY
validator_assert_contains "$tmpdir/out" 'bytes 8'
validator_assert_contains "$tmpdir/out" 'chars 5'
