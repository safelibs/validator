#!/usr/bin/env bash
# @testcase: usage-python3-gi-r16-bytes-new-and-get-data-roundtrip
# @title: PyGObject GLib.Bytes.new + get_data round-trips a Python bytes buffer
# @description: Constructs a GLib.Bytes object via GLib.Bytes.new on a known 16-byte payload, then asserts get_size returns 16 and get_data() returns the same bytes, exercising the immutable-byte-buffer round-trip path.
# @timeout: 60
# @tags: usage, python, bytes
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
payload = bytes(range(16))
b = GLib.Bytes.new(payload)
data = bytes(b.get_data())
print("size=" + str(b.get_size()))
print("match=" + str(data == payload))
print("hex=" + data.hex())
PY

validator_assert_contains "$tmpdir/out" 'size=16'
validator_assert_contains "$tmpdir/out" 'match=True'
validator_assert_contains "$tmpdir/out" 'hex=000102030405060708090a0b0c0d0e0f'
