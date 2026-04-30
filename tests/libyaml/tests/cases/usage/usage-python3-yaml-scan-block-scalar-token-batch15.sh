#!/usr/bin/env bash
# @testcase: usage-python3-yaml-scan-block-scalar-token-batch15
# @title: PyYAML scan emits a ScalarToken for a literal block scalar value
# @description: Feeds a mapping whose value is a literal-block scalar (introduced by '|') to yaml.scan and verifies a yaml.tokens.ScalarToken is emitted whose value carries the multi-line literal body verbatim, alongside the framing BlockMapping and Key/Value tokens.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-scan-block-scalar-token-batch15"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/out"
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
out_path = sys.argv[2]

source = "body: |\n  first line\n  second line\n"
tokens = list(yaml.scan(source))

# Stream framing must appear exactly once each.
assert isinstance(tokens[0], StreamStartToken), tokens[0]
assert isinstance(tokens[-1], StreamEndToken), tokens[-1]

# Block-mapping framing is emitted because of the implicit block layout.
assert any(isinstance(t, BlockMappingStartToken) for t in tokens), tokens
assert any(isinstance(t, KeyToken) for t in tokens), tokens
assert any(isinstance(t, ValueToken) for t in tokens), tokens

scalars = [t for t in tokens if isinstance(t, ScalarToken)]
# Two scalars: the key "body" and the literal block body.
assert len(scalars) == 2, scalars
assert scalars[0].value == "body", scalars[0].value
# Literal block preserves both lines (and their trailing newlines under clip mode).
assert "first line" in scalars[1].value, scalars[1].value
assert "second line" in scalars[1].value, scalars[1].value
# Style "|" identifies the literal block scalar.
assert scalars[1].style == "|", scalars[1].style

with open(out_path, "w", encoding="utf-8") as fh:
    fh.write(f"key={scalars[0].value!r}\n")
    fh.write(f"value={scalars[1].value!r}\n")
    fh.write(f"style={scalars[1].style!r}\n")

print("SCAN_BLOCK_OK", len(tokens))
PYCASE

validator_assert_contains "$tmpdir/out" "key='body'"
validator_assert_contains "$tmpdir/out" "style='|'"
echo "OK"
