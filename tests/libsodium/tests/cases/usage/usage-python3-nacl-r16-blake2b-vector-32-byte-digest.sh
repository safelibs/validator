#!/usr/bin/env bash
# @testcase: usage-python3-nacl-r16-blake2b-vector-32-byte-digest
# @title: PyNaCl nacl.hash.blake2b returns a deterministic 32-byte hex digest for a fixed message
# @description: Computes nacl.hash.blake2b twice over the same payload with digest_size=32 and the HexEncoder, asserts the output is a 64-character hex string identical across the two calls, and asserts that a different payload yields a different digest, exercising libsodium's BLAKE2b binding.
# @timeout: 60
# @tags: usage, crypto, blake2b, python, r16
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import nacl.hash
from nacl.encoding import HexEncoder

msg_a = b"r16 nacl blake2b payload"
msg_b = b"r16 nacl blake2b payload!"

h1 = nacl.hash.blake2b(msg_a, digest_size=32, encoder=HexEncoder)
h2 = nacl.hash.blake2b(msg_a, digest_size=32, encoder=HexEncoder)
h3 = nacl.hash.blake2b(msg_b, digest_size=32, encoder=HexEncoder)

assert isinstance(h1, bytes), type(h1)
assert len(h1) == 64, len(h1)
assert h1 == h2, "blake2b non-deterministic"
assert h1 != h3, "blake2b collided"
int(h1, 16)  # all-hex
print("ok", h1.decode())
PY
