#!/usr/bin/env bash
# @testcase: usage-python3-nacl-utils-random-large
# @title: python3 nacl random 64 bytes
# @description: Requests 64 random bytes through PyNaCl utils.random and verifies the returned buffer length.
# @timeout: 180
# @tags: usage, python, random
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-nacl-utils-random-large"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE'
from nacl.utils import random
value = random(64)
assert len(value) == 64
print(len(value))
PYCASE
