#!/usr/bin/env bash
# @testcase: usage-python3-nacl-signing-key-bytes
# @title: python3-nacl signing key bytes
# @description: Exercises python3-nacl signing key bytes through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-nacl-signing-key-bytes"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE'
from nacl.signing import SigningKey
seed = SigningKey.generate().encode()
assert len(seed) == 32
print(len(seed))
PYCASE
