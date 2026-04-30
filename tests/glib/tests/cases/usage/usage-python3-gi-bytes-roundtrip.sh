#!/usr/bin/env bash
# @testcase: usage-python3-gi-bytes-roundtrip
# @title: PyGObject GLib Bytes get_data round trip
# @description: Builds a GLib.Bytes from a non-ASCII Python bytes payload, calls get_data, and verifies the round-tripped buffer matches the input byte-for-byte.
# @timeout: 180
# @tags: usage, glib, python
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-bytes-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
payload = bytes(range(256))
buf = GLib.Bytes.new(payload)
roundtrip = bytes(buf.get_data())
print(f"size={buf.get_size()}")
print(f"equal={roundtrip == payload}")
print(f"length={len(roundtrip)}")
print(f"head_hex={roundtrip[:4].hex()}")
print(f"tail_hex={roundtrip[-4:].hex()}")
PY

validator_assert_contains "$tmpdir/out" 'size=256'
validator_assert_contains "$tmpdir/out" 'equal=True'
validator_assert_contains "$tmpdir/out" 'length=256'
validator_assert_contains "$tmpdir/out" 'head_hex=00010203'
validator_assert_contains "$tmpdir/out" 'tail_hex=fcfdfeff'
