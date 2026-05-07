#!/usr/bin/env bash
# @testcase: usage-python3-nacl-r15-signing-key-base32-roundtrip
# @title: PyNaCl SigningKey round-trips through Base32Encoder back to identical bytes
# @description: Builds a SigningKey from a fixed 32-byte seed, encodes it with Base32Encoder, asserts the encoded form is upper-case Base32 alphabet (A-Z 2-7) only with optional '=' padding, reconstructs the SigningKey from the encoded form via the same encoder, and asserts the reconstructed key signs a fixed message to a byte-identical detached signature against the original.
# @timeout: 120
# @tags: usage, crypto, signing, base32, python, r15
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import re
from nacl.signing import SigningKey
from nacl.encoding import Base32Encoder, RawEncoder

seed = bytes([0x15]) * 32
sk = SigningKey(seed)

encoded = sk.encode(encoder=Base32Encoder)
assert isinstance(encoded, bytes), type(encoded)
# RFC 4648 Base32 alphabet (uppercase): A-Z and 2-7, plus '=' padding.
assert re.fullmatch(rb"[A-Z2-7]+={0,6}", encoded), encoded

sk_round = SigningKey(encoded, encoder=Base32Encoder)
assert sk_round.encode(encoder=RawEncoder) == bytes(sk)

# Both keys produce identical detached signatures over the same message.
msg = b"r15 base32 signing roundtrip payload"
sig_a = sk.sign(msg).signature
sig_b = sk_round.sign(msg).signature
assert sig_a == sig_b, "round-tripped signing key produced different signature"

print("ok", len(encoded))
PY
