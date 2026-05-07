#!/usr/bin/env bash
# @testcase: usage-python3-gi-r14-bytes-new-get-data-roundtrip
# @title: PyGObject GLib.Bytes.new round-trips a payload through get_data and get_size
# @description: Constructs a GLib.Bytes from a 5-byte payload via GLib.Bytes.new, asserts get_size returns 5, and asserts bytes(get_data()) equals the original payload byte-for-byte.
# @timeout: 60
# @tags: usage, python, bytes
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
payload = b"r14ok"
b = GLib.Bytes.new(payload)
print("size", b.get_size())
data = b.get_data()
print("equal", bytes(data) == payload)
print("len", len(bytes(data)))
PY

validator_assert_contains "$tmpdir/out" 'size 5'
validator_assert_contains "$tmpdir/out" 'equal True'
validator_assert_contains "$tmpdir/out" 'len 5'
