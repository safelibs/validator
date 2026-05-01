#!/usr/bin/env bash
# @testcase: usage-python3-nacl-utils-random-distinct
# @title: PyNaCl nacl.utils.random produces distinct buffers across calls
# @description: Calls nacl.utils.random(32) five times and asserts every returned buffer has the requested length and that every pair of buffers is distinct, confirming PyNaCl's libsodium-backed CSPRNG is not stuck on a constant value. The probability of an accidental collision over five 256-bit draws is vanishingly small, so a repeat indicates a real RNG fault.
# @timeout: 180
# @tags: usage, python, random
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE'
from nacl.utils import random

samples = [random(32) for _ in range(5)]
for i, s in enumerate(samples):
    if not isinstance(s, (bytes, bytearray)):
        raise SystemExit(f"sample {i} is not bytes-like: {type(s)!r}")
    if len(s) != 32:
        raise SystemExit(f"sample {i} length {len(s)} != 32")

distinct = {bytes(s) for s in samples}
if len(distinct) != len(samples):
    raise SystemExit(f"random produced duplicates: {len(distinct)}/{len(samples)}")

# Also forbid an obviously broken all-zero buffer.
if any(s == b"\x00" * 32 for s in samples):
    raise SystemExit("random produced an all-zero 32-byte buffer")

print("ok", len(samples), len(distinct))
PYCASE
