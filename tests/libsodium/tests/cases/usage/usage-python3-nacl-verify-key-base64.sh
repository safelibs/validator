#!/usr/bin/env bash
# @testcase: usage-python3-nacl-verify-key-base64
# @title: python3-nacl verify key base64
# @description: Exercises python3-nacl verify key base64 through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-nacl-verify-key-base64"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE'
from nacl.encoding import Base64Encoder
from nacl.signing import SigningKey
value = SigningKey.generate().verify_key.encode(encoder=Base64Encoder).decode()
assert len(value) > 40
print(value[:16])
PYCASE
