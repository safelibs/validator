#!/usr/bin/env bash
# @testcase: usage-python3-nacl-r10-randombytes-deterministic
# @title: PyNaCl randombytes_buf_deterministic is stable for a fixed seed
# @description: Calls nacl.bindings.randombytes_buf_deterministic with a fixed 32-byte seed twice and asserts both 64-byte outputs are byte-identical, then asserts a different seed produces a different stream.
# @timeout: 180
# @tags: usage, crypto, python, random
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
from nacl.bindings import randombytes_buf_deterministic

seed_a = bytes(range(32))
seed_b = bytes((b ^ 0xFF) for b in seed_a)

out1 = randombytes_buf_deterministic(64, seed_a)
out2 = randombytes_buf_deterministic(64, seed_a)
out3 = randombytes_buf_deterministic(64, seed_b)

assert isinstance(out1, bytes), type(out1)
assert len(out1) == 64, len(out1)
assert out1 == out2, "same seed must produce same stream"
assert out1 != out3, "different seed must produce different stream"
# A non-trivial output should not be all zeros.
assert out1 != bytes(64), "deterministic stream is unexpectedly all-zero"
print("ok", len(out1))
PY
