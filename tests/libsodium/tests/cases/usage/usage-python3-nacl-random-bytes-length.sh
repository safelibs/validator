#!/usr/bin/env bash
# @testcase: usage-python3-nacl-random-bytes-length
# @title: PyNaCl random bytes length
# @description: Allocates random bytes with PyNaCl utilities and verifies the returned byte count.
# @timeout: 120
# @tags: usage
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-nacl-random-bytes-length"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE'
from nacl.utils import random
value = random(12)
assert len(value) == 12
print(len(value))
PYCASE
