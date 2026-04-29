#!/usr/bin/env bash
# @testcase: usage-python3-nacl-signing-deterministic
# @title: python3 nacl deterministic signing
# @description: Signs the same payload twice from a fixed seed through PyNaCl SigningKey and verifies the deterministic Ed25519 signatures match.
# @timeout: 180
# @tags: usage, python, signing
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-nacl-signing-deterministic"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE'
from nacl.signing import SigningKey
seed = b'\x01' * 32
sk_a = SigningKey(seed)
sk_b = SigningKey(seed)
sig_a = sk_a.sign(b'detsig payload').signature
sig_b = sk_b.sign(b'detsig payload').signature
assert sig_a == sig_b
print(len(sig_a))
PYCASE
