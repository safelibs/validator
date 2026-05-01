#!/usr/bin/env bash
# @testcase: usage-python3-nacl-encoding-base16
# @title: PyNaCl nacl.encoding.Base16Encoder roundtrip
# @description: Hashes a fixed input with nacl.hash.sha256 using Base16Encoder, asserts the encoded digest is the documented 64-character uppercase hex string for the FIPS 180-4 "abc" SHA-256 test vector, and round-trips the digest through Base16Encoder.decode back to the raw 32-byte digest produced with RawEncoder. Exercises PyNaCl's Base16Encoder against a libsodium-backed hash output.
# @timeout: 180
# @tags: usage, python, hash, encoding
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE'
from nacl.hash import sha256
from nacl.encoding import Base16Encoder, RawEncoder

expected_hex = b"BA7816BF8F01CFEA414140DE5DAE2223B00361A396177A9CB410FF61F20015AD"

encoded = sha256(b"abc", encoder=Base16Encoder)
if encoded != expected_hex:
    raise SystemExit(f"unexpected base16 digest: {encoded!r}")
if len(encoded) != 64:
    raise SystemExit(f"unexpected base16 length: {len(encoded)}")

raw = sha256(b"abc", encoder=RawEncoder)
if len(raw) != 32:
    raise SystemExit(f"unexpected raw digest length: {len(raw)}")

decoded = Base16Encoder.decode(encoded)
if decoded != raw:
    raise SystemExit("Base16Encoder.decode did not round-trip to raw digest")

print("ok", len(encoded), len(raw))
PYCASE
