#!/usr/bin/env bash
# @testcase: usage-python3-secrets-token-hex
# @title: python os.urandom token hex via libc6 getrandom
# @description: Reads 16 random bytes via os.urandom (which is backed by libc6 getrandom on Linux) and verifies the hex-encoded form has exactly 32 lowercase hex characters, exercising the libc6 entropy path that python3-minimal provides.
# @timeout: 120
# @tags: usage, python, crypto
# @client: python3-minimal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-secrets-token-hex"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' >"$tmpdir/out"
import os
import re
raw = os.urandom(16)
assert len(raw) == 16, len(raw)
tok = raw.hex()
assert len(tok) == 32, len(tok)
assert re.fullmatch(r'[0-9a-f]{32}', tok), tok
print("len=%d ok" % len(tok))
PY

validator_assert_contains "$tmpdir/out" 'len=32 ok'
