#!/usr/bin/env bash
# @testcase: usage-python3-nacl-random-size
# @title: PyNaCl random size
# @description: Exercises pynacl random size through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-nacl-random-size"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
from nacl.utils import random
value = random(24)
assert len(value) == 24
print(len(value))
PY
