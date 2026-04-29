#!/usr/bin/env bash
# @testcase: usage-python3-nacl-blake2b-personal
# @title: python3 nacl blake2b personalised
# @description: Computes a personalised BLAKE2b digest twice through PyNaCl and verifies the personalisation argument produces a stable digest.
# @timeout: 180
# @tags: usage, python, hash
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-nacl-blake2b-personal"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE'
from nacl.hash import blake2b
from nacl.encoding import HexEncoder
digest_a = blake2b(b'payload', person=b'validator-app000', encoder=HexEncoder)
digest_b = blake2b(b'payload', person=b'validator-app000', encoder=HexEncoder)
assert digest_a == digest_b
print(digest_a[:16].decode())
PYCASE
