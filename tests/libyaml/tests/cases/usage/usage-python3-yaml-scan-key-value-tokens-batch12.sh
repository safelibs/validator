#!/usr/bin/env bash
# @testcase: usage-python3-yaml-scan-key-value-tokens-batch12
# @title: PyYAML scan key value tokens
# @description: Scans a block mapping with PyYAML and verifies BlockMappingStartToken, KeyToken, ValueToken, and ScalarToken values appear in the token stream.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-scan-key-value-tokens-batch12"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" >"$tmpdir/out"
import sys
import yaml
from yaml.tokens import (
    BlockMappingStartToken,
    KeyToken,
    ScalarToken,
    StreamEndToken,
    StreamStartToken,
    ValueToken,
)

case_id = sys.argv[1]

tokens = list(yaml.scan("greeting: hello\n"))
names = [type(t).__name__ for t in tokens]

assert names[0] == "StreamStartToken", names
assert names[-1] == "StreamEndToken", names
assert "BlockMappingStartToken" in names, names
assert names.count("KeyToken") >= 1
assert names.count("ValueToken") >= 1

scalars = [t.value for t in tokens if isinstance(t, ScalarToken)]
assert scalars == ["greeting", "hello"], scalars

print("TOKEN_NAMES", ",".join(names))
print("SCALARS", ",".join(scalars))
print("OK")
PYCASE

validator_assert_contains "$tmpdir/out" "BlockMappingStartToken"
validator_assert_contains "$tmpdir/out" "SCALARS greeting,hello"
validator_assert_contains "$tmpdir/out" "OK"
echo "OK"
