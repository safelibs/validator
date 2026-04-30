#!/usr/bin/env bash
# @testcase: usage-python3-yaml-scan-flow-sequence-tokens-batch13
# @title: PyYAML scan tokens for flow sequence [1,2,3]
# @description: Scans the flow sequence "[1,2,3]" with yaml.scan and verifies FlowSequenceStart/End tokens, FlowEntry separators, and three scalar tokens with the expected values.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-scan-flow-sequence-tokens-batch13"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" | tee "$tmpdir/out"
import sys
import yaml
from yaml.tokens import (
    FlowSequenceStartToken,
    FlowSequenceEndToken,
    FlowEntryToken,
    ScalarToken,
)

case_id = sys.argv[1]

tokens = list(yaml.scan("[1,2,3]\n"))
types = [type(tok).__name__ for tok in tokens]

assert any(isinstance(t, FlowSequenceStartToken) for t in tokens), types
assert any(isinstance(t, FlowSequenceEndToken) for t in tokens), types

scalars = [t.value for t in tokens if isinstance(t, ScalarToken)]
assert scalars == ["1", "2", "3"], scalars

flow_entries = sum(1 for t in tokens if isinstance(t, FlowEntryToken))
assert flow_entries == 2, flow_entries

print("SCALARS", ",".join(scalars))
print("FLOW_ENTRIES", flow_entries)
print("OK")
PYCASE

validator_assert_contains "$tmpdir/out" "SCALARS 1,2,3"
validator_assert_contains "$tmpdir/out" "FLOW_ENTRIES 2"
validator_assert_contains "$tmpdir/out" "OK"
echo "OK"
