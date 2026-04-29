#!/usr/bin/env bash
# @testcase: usage-python3-nacl-sha512
# @title: PyNaCl SHA512 hash
# @description: Exercises pynacl sha512 hash through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-nacl-sha512"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
from nacl.encoding import HexEncoder
from nacl.hash import sha512
digest = sha512(b'payload', encoder=HexEncoder).decode()
assert len(digest) == 128
print(digest[:16])
PY
