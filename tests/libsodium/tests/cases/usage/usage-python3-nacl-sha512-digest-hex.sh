#!/usr/bin/env bash
# @testcase: usage-python3-nacl-sha512-digest-hex
# @title: PyNaCl SHA512 digest hex
# @description: Hashes a payload with PyNaCl SHA512 and verifies the emitted hexadecimal digest length.
# @timeout: 120
# @tags: usage
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-nacl-sha512-digest-hex"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE'
from nacl.hash import sha512
digest = sha512(b'validator').decode()
assert len(digest) == 128
print(digest[:16])
PYCASE
