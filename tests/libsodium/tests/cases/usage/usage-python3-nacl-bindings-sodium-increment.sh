#!/usr/bin/env bash
# @testcase: usage-python3-nacl-bindings-sodium-increment
# @title: PyNaCl bindings.sodium_increment little-endian carry
# @description: Calls nacl.bindings.sodium_increment on a 16-byte little-endian counter starting at 0xff..ff in the low byte to assert the carry propagates and the function returns the buffer untouched in length, and runs a second increment from all-zero to confirm the result is exactly 0x01 followed by zeros.
# @timeout: 60
# @tags: usage, sodium, python, bindings
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
from nacl import bindings

# Increment from all-zero -> 01 00 00 ...
zero = bytes(16)
incremented = bindings.sodium_increment(zero)
assert len(incremented) == 16, f"unexpected len: {len(incremented)}"
expected = b"\x01" + bytes(15)
assert incremented == expected, incremented.hex()

# Carry across a byte boundary: 0xff in low byte should roll into byte 1.
carry_in = b"\xff" + bytes(15)
carry_out = bindings.sodium_increment(carry_in)
assert len(carry_out) == 16
assert carry_out == b"\x00\x01" + bytes(14), carry_out.hex()

# Wrap-around: all 0xff -> all 0x00 (counter mod 2^128).
all_ff = b"\xff" * 16
wrapped = bindings.sodium_increment(all_ff)
assert wrapped == bytes(16), wrapped.hex()

print("ok", incremented.hex(), carry_out.hex(), wrapped.hex())
PY
