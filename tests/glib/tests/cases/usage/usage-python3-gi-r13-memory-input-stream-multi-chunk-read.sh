#!/usr/bin/env bash
# @testcase: usage-python3-gi-r13-memory-input-stream-multi-chunk-read
# @title: PyGObject Gio.MemoryInputStream reads bytes back across two read_bytes calls
# @description: Builds a MemoryInputStream from a 12-byte payload, reads two 6-byte chunks via read_bytes, and asserts the concatenated bytes equal the original input.
# @timeout: 60
# @tags: usage, python, gio, stream
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import Gio

payload = b"abcdef-r13!!"
stream = Gio.MemoryInputStream.new_from_data(payload, None)
first = stream.read_bytes(6, None).get_data()
second = stream.read_bytes(6, None).get_data()
print("first=" + first.decode("utf-8"))
print("second=" + second.decode("utf-8"))
print("joined=" + (first + second).decode("utf-8"))
PY

validator_assert_contains "$tmpdir/out" 'first=abcdef'
validator_assert_contains "$tmpdir/out" 'second=-r13!!'
validator_assert_contains "$tmpdir/out" 'joined=abcdef-r13!!'
