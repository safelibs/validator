#!/usr/bin/env bash
# @testcase: usage-python3-gi-batch12-base64-roundtrip-binary
# @title: PyGObject GLib.base64_encode/decode binary roundtrip
# @description: Encodes binary bytes including NULs with GLib.base64_encode and decodes back via GLib.base64_decode, verifying the bytes round-trip exactly.
# @timeout: 60
# @tags: usage, python, base64
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
src = bytes(range(256))
encoded = GLib.base64_encode(src)
decoded = bytes(GLib.base64_decode(encoded))
print("encoded_len", len(encoded))
print("decoded_len", len(decoded))
print("match", decoded == src)
assert decoded == src
assert "=" not in encoded[:-3] or encoded.endswith("=") or encoded.endswith("==") or "=" not in encoded
PY
validator_assert_contains "$tmpdir/out" 'decoded_len 256'
validator_assert_contains "$tmpdir/out" 'match True'
